import Foundation
import ParsecSDK
import SwiftUI

struct ParsecStatusBar: View {
	@Binding var showMenu: Bool
	@State var metricInfo: String = "Loading..."
	@Binding var showDCAlert: Bool
	@Binding var DCAlertText: String
	let timer = Timer.publish(every: 0.2, on: .main, in: .common).autoconnect()
	
	var body: some View {
		// Overlay elements
		if showMenu {
			VStack {
				Text(metricInfo)
					.frame(minWidth: 200, maxWidth: .infinity, maxHeight: 20)
					.multilineTextAlignment(.leading)
					.font(.system(size: 10))
					.lineSpacing(20)
					.lineLimit(nil)
			}
			.background(Rectangle().fill(Color("BackgroundPrompt").opacity(0.75)))
			.foregroundColor(Color("Foreground"))
			.frame(maxHeight: .infinity, alignment: .top)
			.zIndex(1)
			.edgesIgnoringSafeArea(.all)
		}
		EmptyView()
			.onReceive(timer) { _ in
				poll()
			}
	}
	
	func poll() {
		if showDCAlert {
			return // no need to poll if we aren't connected anymore
		}
		
		var pcs = ParsecClientStatus()
		let status = CParsec.getStatusEx(&pcs)
		
		if status != PARSEC_OK {
			DCAlertText = "Disconnected (code \(status.rawValue))"
			showDCAlert = true
			return
		}

		// FIXME: This may cause memory leak?
		
//		if showMenu {
//			let str = String.fromBuffer(&pcs.decoder.0.name.0, length: 16)
//			metricInfo = "Decode \(String(format: "%.2f", pcs.`self`.metrics.0.decodeLatency))ms    Encode \(String(format: "%.2f", pcs.`self`.metrics.0.encodeLatency))ms    Network \(String(format: "%.2f", pcs.`self`.metrics.0.networkLatency))ms    Bitrate \(String(format: "%.2f", pcs.`self`.metrics.0.bitrate))Mbps    \(pcs.decoder.0.h265 ? "H265" : "H264") \(pcs.decoder.0.width)x\(pcs.decoder.0.height) \(pcs.decoder.0.color444 ? "4:4:4" : "4:2:0") \(str)"
//		}
	}
}

struct ParsecView: View {
	var controller: ContentView?
	
	@State var showDCAlert: Bool = false
	@State var DCAlertText: String = "Disconnected (reason unknown)"
	@State var metricInfo: String = "Loading..."
	
	@State var hideOverlay: Bool = false
	@State var showMenu: Bool = false

	@State var muted: Bool = false
	@State var preferH265: Bool = true
	@State var constantFps = false
	
	@State var resolutions: [ParsecResolution]
	@State var bitrates: [Int]
	
	var parsecViewController: ParsecViewController!
	
	// @State var showDisplays:Bool = false
	
	init(_ controller: ContentView?) {
		self.controller = controller
		parsecViewController = ParsecViewController()
		_resolutions = State(initialValue: ParsecResolution.resolutions)
		_bitrates = State(initialValue: ParsecResolution.bitrates)
	}

	var body: some View {
		ZStack {
			UIViewControllerWrapper(self.parsecViewController)
				.zIndex(1)
				.prefersPersistentSystemOverlaysHidden()
			
//			ParsecStatusBar(showMenu: $showMenu, showDCAlert: $showDCAlert, DCAlertText: $DCAlertText)
		}
		.overlay(alignment: .topLeading, content: {
			if !hideOverlay {
				Button(action: {
					if showMenu {
						showMenu = false
					} else {
						showMenu = true
						getHostUserData()
					}
				}) {
					Image("IconTransparent")
						.resizable()
						.aspectRatio(contentMode: .fit)
						.frame(width: 48, height: 48)
						.opacity(showMenu ? 1 : 0.25)
				}
				.padding()
				.clipShape(RoundedRectangle(cornerRadius: 16))
				.popover(isPresented: $showMenu) {
					List {
						Section {
//							Button(action: disableOverlay) {
//								Text("Hide Overlay")
//							}
							Toggle("Mute", isOn: Binding(get: {
								muted
							}, set: { newValue in
								toggleMute(isOn: newValue)
							}))
							Picker(selection: Binding(get: {
								DataManager.model.resolution
							}, set: { newResolution in
								changeResolution(res: newResolution)
							})) {
								ForEach(resolutions, id: \.self) { resolution in
									Button(resolution.desc) {
										changeResolution(res: resolution)
									}
								}
							} label: {
								Text("Resolution")
							}

							Picker(selection: Binding(get: { DataManager.model.bitrate },
							                          set: { bitrate in
							                          	changeBitRate(bitrate: bitrate)
							                          }), content: {
									ForEach(bitrates, id: \.self) { bitrate in
										Text("\(bitrate) Mbps").tag(bitrate)
									}
								}, label: {
									Text("BitRate")
								})
							if DataManager.model.displayConfigs.count > 1 {
								Picker(selection: Binding(get: {
									DataManager.model.output
								}, set: { newDisplay in
									changeDisplay(displayId: newDisplay)
								}), content: {
									Text("Auto").tag("none")
									ForEach(DataManager.model.displayConfigs, id: \.self) { config in
										Text("\(config.name) \(config.adapterName)").tag(config.id)
									}
								}, label: {
									Text("Switch Display")
								})
							}
							Toggle("Constant FPS", isOn: Binding(get: { constantFps }, set: { newValue in
								toggleConstantFps(isOn: newValue)
							}))
						}
						Section {
							Button(role: .destructive) {
								disconnect()
							}
							label: {
								Text("Disconnect")
									.foregroundColor(.red)
							}
						}
					}
					.frame(width: 256)
					.frame(minHeight: 256)
				}
			}
		})
		.statusBarHidden(SettingsHandler.hideStatusBar)
		.alert(isPresented: $showDCAlert) {
			Alert(title: Text(DCAlertText), dismissButton: .default(Text("Close"), action: disconnect))
		}
		.onAppear(perform: post)
		.edgesIgnoringSafeArea(.all)
	}
	
	func post() {
		CParsec.applyConfig()
		CParsec.setMuted(muted)
		
		// set client resolution
		let screenSize: CGSize = self.parsecViewController.view.frame.size
		let scaleFactor = parsecViewController.view.window?.windowScene?.screen.scale ?? 1
		ParsecResolution.resolutions[1].width = Int(screenSize.width * scaleFactor)
		ParsecResolution.resolutions[1].height = Int(screenSize.height * scaleFactor)
		
		getHostUserData()
		
		hideOverlay = SettingsHandler.noOverlay
	}
	
	func disableOverlay() {
		hideOverlay = true
		showMenu = false
	}
	
	func toggleMute(isOn: Bool) {
		muted = isOn
		CParsec.setMuted(muted)
	}
	
	/* func genDisplaySheet() -> ActionSheet
	 {
	 	let len:Int = 16
	 	var outputs = [ParsecOutput?](repeating:nil, count:len)
	 	ParsecGetOutputs(&outputs, UInt32(len))
	 	print("Listing \(outputs.count) displays")

	 	func getDeviceName(_ output:ParsecOutput) -> String
	 	{
	 		return withUnsafePointer(to:output.device)
	 		{
	 			$0.withMemoryRebound(to:UInt8.self, capacity:MemoryLayout.size(ofValue:$0))
	 			{
	 				String(cString:$0)
	 			}
	 		}
	 	}

	 	let buttons = outputs.enumerated().map
	 	{ i, output in
	 		Alert.Button.default(Text("\(i) - \(getDeviceName(output))"), action:{print("Selected device \(i)")})
	 	}
	 	return ActionSheet(title:Text("Select a Display:"), buttons:buttons + [Alert.Button.cancel()])
	 } */
	
	func disconnect() {
		CParsec.disconnect()
		parsecViewController.glkView.cleanUp()

		if let c = controller {
			c.setView(.main)
		}
	}
	
	func changeResolution(res: ParsecResolution) {
		DataManager.model.resolution = res
		CParsec.updateHostVideoConfig()
	}

	func changeBitRate(bitrate: Int) {
		DataManager.model.bitrate = bitrate
		CParsec.updateHostVideoConfig()
	}
	
	func toggleConstantFps(isOn: Bool) {
		DataManager.model.constantFps = isOn
		constantFps = isOn
		CParsec.updateHostVideoConfig()
	}
	
	func changeDisplay(displayId: String) {
		DataManager.model.output = displayId
		CParsec.updateHostVideoConfig()
	}
	
	func getHostUserData() {
		let data = "".data(using: .utf8)!
		CParsec.sendUserData(type: .getVideoConfig, message: data)
		CParsec.sendUserData(type: .getAdapterInfo, message: data)
	}
}

// from https://github.com/utmapp/UTM/blob/117e3a962f2f46f7d847632d65fa7a85a2bb0cfa/Platform/iOS/VMWindowView.swift#L314
private extension View {
	func prefersPersistentSystemOverlaysHidden() -> some View {
		if #available(iOS 16, *) {
			return persistentSystemOverlays(.hidden)
		} else {
			return self
		}
	}
}
