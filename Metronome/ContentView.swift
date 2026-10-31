import AudioToolbox
import SwiftUI
import WrappingHStack

struct TempoItem {
	var tempo:Int
	var signature:String
}

struct ContentView: View {
	private let signatures = ["3/4", "6/8", "4/4", "5/4", "12/8"]
	@State private var tempo = 160
	@State private var signature = "4/4"
	@State private var isRunning = false
	@State private var activeBeat: Int?
	@State private var nextTempo: Int? = nil
	@State private var nextSignature: String? = nil
	@State private var savedOptions: [(Int,String)] = [(160,"4/4")]

	var beatCount: Int {
		Int(signature.split(separator: "/").first ?? "4") ?? 4
	}

	var tempoOptions = [-10, -1, +1, +10]

	var body: some View {
		VStack(spacing: 8) {
			Text("\(tempo)").font(.system(size: 92))
			HStack(spacing: 8) {
				ForEach(tempoOptions, id: \.self) { opt in
					let optText = opt < 0 ? "\(opt)" : "+\(opt)"
					Button("\(optText)") {
						tempo += opt
					}
					.controlSize(.large)
					.buttonStyle(.glass)
					if opt == -1 {
						Spacer()
					}
				}
			}
			.frame(maxWidth: .infinity)
			Picker("Signature", selection: $signature) {
				ForEach(signatures, id: \.self) { value in
					Text(value).tag(value)
				}
			}
			.pickerStyle(.wheel)
			.onChange(of: signature) {
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
					if !savedOptions.contains(where: {(x,y) in
						return x == tempo && y == signature
					}) {
						savedOptions.append((tempo,signature))
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
				ForEach(savedOptions, id: \.self.1) { tempo in
					Button("\(tempo.0) - \(tempo.1)") {
						nextTempo = tempo.0
						nextSignature = tempo.1
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
				if nextBeat == 0 && nextTempo != nil {
					tempo = nextTempo!
					nextTempo = nil
					signature = nextSignature!
					nextSignature = nil
				}
				AudioServicesPlaySystemSound(nextBeat == 0 ? 1057 : 1104)

				do {
					let denominator =
						Double(signature.split(separator: "/").last ?? "4") ?? 4
					try await Task.sleep(
						for: .seconds(60.0 / Double(tempo) * 4.0 / denominator)
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
