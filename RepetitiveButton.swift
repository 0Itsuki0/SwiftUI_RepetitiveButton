//
//  RepetitiveButton.swift
//  iOSDemo2
//
//  Created by Itsuki on 2025/11/14.
//

import SwiftUI
import Combine

struct RepetitiveButtonDemo: View {
    @State private var count = 0
    
    // to control the spin off button, ie: Stop repeating on tap anywhere outside
    @State private var isPressing = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Text(count, format: .number)
                    .font(.system(size: 48))
                    .bold()
                    .contentTransition(.numericText())
                    
                Divider()
                
                VStack(spacing: 24) {
                    Text("Built in With `buttonRepeatBehavior`")
                        .font(.headline)
                    Button(action: {
                        self.increment()
                    }, label: {
                        Text("Built-in")
                    })
                    .buttonRepeatBehavior(.enabled)
                }
                
                Divider()
                
                VStack(spacing: 24) {
                    VStack(spacing: 8) {
                        Text("Custom V1")
                            .font(.headline)
                        
                        Text("""
                     **Traditional repeat Button**: 
                        - repeat on long press
                        - custom delay
                        - variable speed
                    """)
                        .foregroundStyle(.secondary)
                    }
                   
                    CustomRepetitiveButton(count: $count)
                }
                
                Divider()
                
                VStack(spacing: 24) {
                    VStack(spacing: 8) {
                        Text("Custom V2")
                            .font(.headline)
                        
                        Text("""
                     **Spin Off**:
                        - Start repeating on long press 
                            * without keep holding down
                        - Stop repeating on tap outside
                    """)
                        .foregroundStyle(.secondary)
                    }

                    CustomRepetitiveButtonSpinOff(count: $count, isPressing: $isPressing)
                }
            }
            .navigationTitle("Repetitive Button")
            .padding(.vertical, 32)
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(.yellow.opacity(0.1))
            .contentShape(.rect)
            .simultaneousGesture(
                TapGesture().onEnded({ _ in
                    self.isPressing = false
                })
            )

        }
        
    }
    
    private func increment(by value: Int = 1) {
        withAnimation {
            count = count + value
        }
    }
 
}



// Traditional repeat Button: repeat on long press
// - custom delay on starting the repeat
// - variable speed
struct CustomRepetitiveButton: View {
    @Binding var count: Int
    
    // a delay before the first action occurs and an interval for subsequent actions, ie: when do we want to start the repeat behavior vs treat it as a regular tap
    private let delay: TimeInterval = 0.5
    
    // speed up the increment as user presses longer
    // set speedFactorPerIncrement to 0 to disable variable speed
    private let speedFactorPerIncrement: Int = 1
    private let speedIncrementInterval = 0.2
    private let maxSpeedIncrementPerInterval: Int = 20
    private let baseSpeedIncrementPerInterval: Int = 1
    @State private var startedDate: Date?
    
    @State private var isPressing = false
    @State private var enableRepeatBehavior = false
    
    @State private var timerCancellable: AnyCancellable?
    
    var body: some View {
                
        Text("Custom")
            .foregroundStyle(.blue.opacity(isPressing ? 0.3 : 1.0))
            .onLongPressGesture(minimumDuration: self.delay, perform: {
                // perform will not be triggered if minimumDuration = 0
                self.enableRepeatBehavior = true
            }, onPressingChanged: { isPressed in
                // keep a reference before enableRepeatBehavior get reset
                let enabled = self.enableRepeatBehavior
                self.isPressing = isPressed

                // user release their finger before the gesture is recognized as a long press
                // treat it as a regular tap
                if !isPressed, !enabled {
                    self.increment()
                    return
                }
                
                // perform will not be triggered if minimumDuration(delay) = 0,
                // therefore, we need to set the enableRepeatBehavior state here.
                if delay == 0 {
                    self.enableRepeatBehavior = isPressed
                }
            })
            .onChange(of: self.isPressing, {
                if !self.isPressing {
                    self.enableRepeatBehavior = false
                }
            })
            .onChange(of: enableRepeatBehavior, {
                if enableRepeatBehavior {
                    self.startedDate = Date()
                    self.timerCancellable = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect().sink { date in
                        let elapsed = if let startedDate = self.startedDate { date.timeIntervalSince(startedDate) } else { 0.0 }
                        var incrementValue: Int = Int(elapsed / self.speedIncrementInterval) * self.speedFactorPerIncrement + baseSpeedIncrementPerInterval
                        incrementValue = max(min(self.maxSpeedIncrementPerInterval, incrementValue), self.baseSpeedIncrementPerInterval)
                        self.increment(by: incrementValue)
                    }
                } else {
                    self.timerCancellable?.cancel()
                    self.timerCancellable = nil
                    self.startedDate = nil
                }
            })

        
    }
    
    private func increment(by value: Int = 1) {
        withAnimation {
            count = count + value
        }
    }
 
}




// Spin Off:
// - Start repeating on long press without keep holding down
// - Stop repeating on tap outside
struct CustomRepetitiveButtonSpinOff: View {
    @Binding var count: Int
    @Binding var isPressing: Bool

    // a delay before the first action occurs and an interval for subsequent actions, ie: when do we want to start the repeat behavior vs treat it as a regular tap
    private let delay: TimeInterval = 0.5
    
    // speed up the increment as user presses longer
    // set speedFactorPerIncrement to 0 to disable variable speed
    private let speedFactorPerIncrement: Int = 1
    private let speedIncrementInterval = 0.2
    private let maxSpeedIncrementPerInterval: Int = 20
    private let baseSpeedIncrementPerInterval: Int = 1
    @State private var startedDate: Date?

    @State private var enableRepeatBehavior = false
    
    @State private var timerCancellable: AnyCancellable?

    var body: some View {
        
        Text("Custom")
            .foregroundStyle(.blue.opacity(isPressing ? 0.3 : 1.0))
            .onLongPressGesture(minimumDuration: self.delay, perform: {
                // perform will not be triggered if minimumDuration = 0
                self.enableRepeatBehavior = true
            }, onPressingChanged: { isPressed in
                if isPressed {
                    self.isPressing = true
                }
                
                // user release their finger before the gesture is recognized as a long press
                // treat it as a regular tap
                if !isPressed, !self.enableRepeatBehavior {
                    self.isPressing = false
                    self.increment()
                    return
                }
                
                // perform will not be triggered if minimumDuration(delay) = 0,
                // therefore, we need to set the enableRepeatBehavior state here.
                if delay == 0, isPressed {
                    self.enableRepeatBehavior = true
                }
            })
            .onChange(of: self.isPressing, {
                if !self.isPressing {
                    self.enableRepeatBehavior = false
                }
            })
            .onChange(of: enableRepeatBehavior, {
                if enableRepeatBehavior {
                    self.startedDate = Date()
                    self.timerCancellable = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect().sink { date in
                        let elapsed = if let startedDate = self.startedDate { date.timeIntervalSince(startedDate) } else { 0.0 }
                        var incrementValue: Int = Int(elapsed / self.speedIncrementInterval) * self.speedFactorPerIncrement + baseSpeedIncrementPerInterval
                        incrementValue = max(min(self.maxSpeedIncrementPerInterval, incrementValue), self.baseSpeedIncrementPerInterval)
                        self.increment(by: incrementValue)
                    }
                } else {
                    self.timerCancellable?.cancel()
                    self.timerCancellable = nil
                    self.startedDate = nil
                }
            })
    }
    
    private func increment(by value: Int = 1) {
        withAnimation {
            count = count + value
        }
    }
 
}




#Preview {
    RepetitiveButtonDemo()
}
