import AudioToolbox
import SwiftUI
import WrappingHStack

enum Signature: String, CaseIterable, Hashable {
	case threeFour = "3/4"
	case sixEight = "6/8"
	case fourFour = "4/4"
	case fiveFour = "5/4"
	case twelveEight = "12/8"
}

struct TempoItem: Hashable {
	var tempo: Int
	var signature: Signature
}

struct ContentView: View {
	@State private var tempoItem = TempoItem(tempo: 160, signature: .fourFour)
	@State private var isRunning = false
	@State private var activeBeat: Int?
	@State private var nextTempoItem: TempoItem?
	@State private var savedOptions: [TempoItem] = [TempoItem(tempo: 160, signature: .fourFour)]
	
	var beatCount: Int {
		Int(tempoItem.signature.rawValue.split(separator: "/").first ?? "4") ?? 4
	}
	
	var tempoOptions = [-10, -1, +1, +10]
	
	var body: some View {
		VStack(spacing: 8) {
			Text("\(tempoItem.tempo)").font(.system(size: 92))
			HStack(spacing: 8) {
				ForEach(tempoOptions, id: \.self) { opt in
					let optText = opt < 0 ? "\(opt)" : "+\(opt)"
					Button("\(optText)") {
						tempoItem.tempo += opt
					}
					.controlSize(.large)
					.buttonStyle(.glass)
					if opt == -1 {
						Spacer()
					}
				}
			}
			.frame(maxWidth: .infinity)
			Picker("Signature", selection: $tempoItem.signature) {
				ForEach(Signature.allCases, id: \.self) { value in
					Text(value.rawValue).tag(value)
				}
			}
			.pickerStyle(.wheel)
			.onChange(of: tempoItem.signature) {
				activeBeat = nil
			}
			HStack(spacing: 12) {
				ForEach(0..<beatCount, id: \.self) { beat in
					Circle()
						.fill(activeBeat == beat ? Color.accentColor : Color.primary)
						.frame(width: 20, height: 20)
						.animation(.easeInOut(duration: 0.08), value: activeBeat)
				}
			}
			Spacer()
			HStack {
				Button(isRunning ? "Stop" : "Start") {
					isRunning = !isRunning
					activeBeat = nil
				}
				.buttonStyle(.glassProminent)
				.controlSize(.extraLarge)
				Spacer()
				Button("Save") {
					if !savedOptions.contains(tempoItem) {
						savedOptions.append(tempoItem)
						if savedOptions.count > 6 {
							savedOptions.remove(at: 0)
						}
					}
				}
				.buttonStyle(.glass)
				.controlSize(.large)
			}
			Spacer()
			WrappingHStack {
				ForEach(savedOptions, id: \.self) { item in
					Button("\(item.tempo) - \(item.signature.rawValue)") {
						nextTempoItem = item
					}.buttonStyle(.glass)
						.controlSize(.large)
				}
			}
		}
		.padding()
		.task(id: isRunning) {
			guard isRunning else { return }
			
			while !Task.isCancelled {
				let nextBeat = activeBeat.map { ($0 + 1) % beatCount } ?? 0
				activeBeat = nextBeat
				if nextBeat == 0 && nextTempoItem != nil {
					tempoItem = nextTempoItem!
					nextTempoItem = nil
				}
				AudioServicesPlaySystemSound(nextBeat == 0 ? 1057 : 1104)
				
				do {
					let denominator =
					Double(tempoItem.signature.rawValue.split(separator: "/").last ?? "4") ?? 4
					try await Task.sleep(
						for: .seconds(60.0 / Double(tempoItem.tempo) * 4.0 / denominator)
					)
				} catch {
					return
				}
			}
		}
	}
}

#Preview {
	ContentView()
}
