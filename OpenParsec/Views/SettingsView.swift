import SwiftUI

struct SettingsView: View {
	@Environment(\.dismiss) var dismiss
	
	// @State var renderer:RendererType = SettingsHandler.renderer
	@State var decoder: DecoderPref = SettingsHandler.decoder
	@State var cursorMode: CursorMode = SettingsHandler.cursorMode
	@State var rightClickPosition: RightClickPosition = SettingsHandler.rightClickPosition
	@State var resolution: ParsecResolution = SettingsHandler.resolution
	@State var cursorScale: Float = SettingsHandler.cursorScale
	@State var mouseSensitivity: Float = SettingsHandler.mouseSensitivity
	@State var noOverlay: Bool = SettingsHandler.noOverlay
	@State var hideStatusBar: Bool = SettingsHandler.hideStatusBar
	
	let resolutionChoices: [Choice<ParsecResolution>]

	init() {
		var tmp: [Choice<ParsecResolution>] = []
		for res in ParsecResolution.resolutions {
			tmp.append(Choice(res.desc, res))
		}
		resolutionChoices = tmp
	}
	
	var body: some View {
		NavigationStack {
			List {
				Section("Interactivity") {
					Picker("Mouse Movement", selection: $cursorMode) {
						Text("Touchpad").tag(CursorMode.touchpad)
						Text("Direct").tag(CursorMode.direct)
					}
					Picker("Right Click Position", selection: $rightClickPosition) {
						Text("First Finger").tag(RightClickPosition.firstFinger)
						Text("Middle").tag(RightClickPosition.middle)
						Text("Second Finger").tag(RightClickPosition.secondFinger)
					}
					LabeledContent {
						Slider(value: $cursorScale, in: 0.1...4, step: 0.1) {
							Text("Cursor Scale")
						} currentValueLabel: {
							Text(String(format: "%.1f", cursorScale))
						}
					} label: {
						Text("Cursor Scale")
					}
					
					LabeledContent {
						Slider(value: $mouseSensitivity, in: 0.1...4, step: 0.1) {
							Text("Mouse Sensitivity")
						} currentValueLabel: {
							Text(String(format: "%.1f", mouseSensitivity))
						}
					} label: {
						Text("Mouse Sensitivity")
					}
				}
				
				Section("Graphics") {
					Picker("Resolution", selection: $resolution) {
						ForEach(resolutionChoices) { resolution in
							Text(resolution.label).tag(resolution.value)
						}
					}
					Picker("Decoder", selection: $decoder) {
						Text("H.264").tag(DecoderPref.h264)
						Text("Prefer H.265").tag(DecoderPref.h265)
					}
				}
				
				Section("Misc") {
					Toggle("Never Show Overlay", isOn: $noOverlay)
						
					Toggle("Hide Status Bar", isOn: $hideStatusBar)
				}
			}
			.navigationTitle("Settings")
			.toolbar {
				ToolbarItem(placement: .confirmationAction) {
					Button(role: .confirm) {
						saveAndExit()
					} label: {
						Label("Confirm", systemImage: "checkmark")
					}
				}
				
				ToolbarItem(placement: .cancellationAction) {
					Button(role: .close) {
						dismiss()
					} label: {
						Label("Close", systemImage: "xmark")
					}
				}
			}
		}
	}
	
	func saveAndExit() {
		// SettingsHandler.renderer = renderer
		SettingsHandler.decoder = decoder
		SettingsHandler.resolution = resolution
		SettingsHandler.cursorMode = cursorMode
		SettingsHandler.cursorScale = cursorScale
		SettingsHandler.rightClickPosition = rightClickPosition
		SettingsHandler.noOverlay = noOverlay
		SettingsHandler.hideStatusBar = hideStatusBar
		SettingsHandler.mouseSensitivity = mouseSensitivity
		SettingsHandler.save()
		
		dismiss()
	}
}

struct SettingsView_Previews: PreviewProvider {
	@State static var value: Bool = true

	static var previews: some View {
		SettingsView()
	}
}
