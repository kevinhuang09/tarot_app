//
//  HomePage.swift
//  TarotApp
//
//  Created by wang  on 2026/5/5.
//

import Foundation

import SwiftUI

struct HomeView: View {
    @Binding var shouldResetQuestion: Bool
    
    var body: some View {
        ZStack {
            AppColors.mainGradient.ignoresSafeArea()
            
            VStack(spacing: 40) {
                
                Spacer()
                
                Text("主畫面")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                NavigationLink(
                    destination: QuestionInputView(
                        shouldReset: $shouldResetQuestion
                    )
                ) {
                    Text("前往占卜")
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(width: 200, height: 50)
                        .background(Color(hex: "1A1B41"))
                        .cornerRadius(10)
                }
                
                Spacer()
            }
        }
        .navigationBarHidden(true)
    }
}
