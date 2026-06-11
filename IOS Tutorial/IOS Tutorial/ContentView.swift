import SwiftUI
internal import Combine

struct ContentView: View {
    
    @State private var score = 0
    @State private var timeRemaining = 10
    @State private var gameOver = false
    
    @State private var comboMultiplier = 1
    @State private var lastTapTime: Date?
    
    @State private var isBonusColour = true
    
    @AppStorage("highScore") private var highScore = 0
    
    let gameTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    let colourTimer = Timer.publish(every: 2, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [.black, .blue],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            if gameOver {
                gameOverView
            } else {
                gameView
            }
        }
        .onReceive(gameTimer) { _ in
            if !gameOver {
                if timeRemaining > 0 {
                    timeRemaining -= 1
                }
                
                if timeRemaining == 0 {
                    endGame()
                }
            }
        }
        .onReceive(colourTimer) { _ in
            if !gameOver {
                isBonusColour.toggle()
            }
        }
    }
    
    var gameView: some View {
        VStack(spacing: 30) {
            
            Text("Tap Frenzy")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            HStack {
                VStack {
                    Text("Score")
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.8))
                    
                    Text("\(score)")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.yellow)
                }
                
                Spacer()
                
                VStack {
                    Text("Time")
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.8))
                    
                    Text("\(timeRemaining)")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.red)
                }
            }
            .padding(.horizontal, 40)
            
            Text("Combo x\(comboMultiplier)")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            Text(isBonusColour ? "Green = Bonus Points" : "Grey = Penalty")
                .font(.headline)
                .foregroundColor(.white.opacity(0.9))
            
            Button {
                tapButtonPressed()
            } label: {
                Text("TAP")
                    .font(.system(size: 45, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 220, height: 220)
                    .background(isBonusColour ? Color.green : Color.gray)
                    .clipShape(Circle())
                    .shadow(radius: 15)
            }
            
            Text("High Score: \(highScore)")
                .font(.title3)
                .foregroundColor(.white)
        }
        .padding()
    }
    
    var gameOverView: some View {
        VStack(spacing: 25) {
            
            Text("Game Over")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text("Final Score")
                .font(.title2)
                .foregroundColor(.white.opacity(0.8))
            
            Text("\(score)")
                .font(.system(size: 70, weight: .bold))
                .foregroundColor(.yellow)
            
            if score == highScore && score > 0 {
                Text("New High Score!")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.green)
            }
            
            Text("High Score: \(highScore)")
                .font(.title3)
                .foregroundColor(.white)
            
            Button {
                restartGame()
            } label: {
                Text("Play Again")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding()
                    .frame(width: 220)
                    .background(Color.blue)
                    .cornerRadius(15)
            }
        }
        .padding()
    }
    
    func tapButtonPressed() {
        let currentTime = Date()
        
        if let lastTap = lastTapTime {
            let difference = currentTime.timeIntervalSince(lastTap)
            
            if difference <= 0.5 {
                comboMultiplier += 1
            } else {
                comboMultiplier = 1
            }
        }
        
        lastTapTime = currentTime
        
        if isBonusColour {
            score += comboMultiplier * 2
        } else {
            score -= 1
            
            if score < 0 {
                score = 0
            }
        }
    }
    
    func endGame() {
        gameOver = true
        
        if score > highScore {
            highScore = score
        }
    }
    
    func restartGame() {
        score = 0
        timeRemaining = 10
        gameOver = false
        comboMultiplier = 1
        lastTapTime = nil
        isBonusColour = true
    }
}

#Preview {
    ContentView()
}
