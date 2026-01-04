import ParsecSDK
import SwiftUI

struct MainView: View
{
	var controller: ContentView?

	@State private var page: Page = .hosts

	// Host page vars
	@State var hostCountStr: String = "0 hosts"
	@State var refreshTime: String = "Last refreshed at 1/1/1970 12:00 AM"

	@State var hosts: [IdentifiableHostInfo] = []

	// Friend page vars
	@State var friendCountStr: String = "0 friends"

	@State var userInfo: IdentifiableUserInfo? = nil
	@State var friends: [IdentifiableUserInfo] = []

	// Global vars
	@State var showBaseAlert: Bool = false
	@State var baseAlertText: String = ""

	@State var showLogoutAlert: Bool = false

	@State var isConnecting: Bool = false
	@State var connectingToName: String = ""
	@State var pollTimer: Timer?

	@State var isRefreshing: Bool = false

	@State var inSettings: Bool = false

	var busy: Bool
	{
		isConnecting || isRefreshing || inSettings
	}

	init(_ controller: ContentView?)
	{
		self.controller = controller
	}

	var hostsPage: some View
	{
		// Hosts page
		ScrollView(.vertical)
		{
			VStack
			{
				Text(refreshTime)
					.multilineTextAlignment(.center)
					.opacity(0.5)
				ForEach(hosts)
				{ i in
					VStack
					{
						if i.connections > 0
						{
							HStack
							{
								Image(systemName: "person.fill")
								Text(String(i.connections))
									.font(.system(size: 16, weight: .medium))
								Spacer()
							}
						}
						URLImage(url: URL(string: "https://parsecusercontent.com/cors-resize-image/w=64,h=64,fit=crop,background=white,q=90,f=jpeg/avatars/\(String(i.user.id))/avatar"),
						         output:
						         {
						         	$0
						         		.resizable()
						         		.aspectRatio(contentMode: .fit)
						         		.frame(width: 64, height: 64)
						         		.cornerRadius(8)
						         },
						         placeholder:
						         {
						         	Image("IconTransparent")
						         		.resizable()
						         		.aspectRatio(contentMode: .fit)
						         		.frame(width: 64, height: 64)
						         		.background(Rectangle().fill(Color("BackgroundPrompt")))
						         		.cornerRadius(8)
						         })
						Text(i.hostname)
							.font(.system(size: 20, weight: .medium))
							.multilineTextAlignment(.center)
						Text("\(i.user.name)#\(String(i.user.id))")
							.font(.system(size: 16, weight: .medium))
							.multilineTextAlignment(.center)
							.opacity(0.5)
						Button(action: { connectTo(i) })
						{
							ZStack
							{
								Rectangle()
									.fill(Color("AccentColor"))
									.cornerRadius(8)
								Text("Connect")
									.foregroundColor(.white)
									.padding(8)
							}
							.frame(maxWidth: 100)
						}
					}

					.padding()
					.frame(maxWidth: 400)
					.background(Rectangle().fill(Color("BackgroundCard")))
					.cornerRadius(8)
				}
			}
			.padding()
		}
		.refreshable(action: refreshHosts)
	}

	var friendsPage: some View
	{
		// Friends page
		ScrollView(.vertical)
		{
			VStack
			{
				if let user = userInfo
				{
					Text("You")
						.multilineTextAlignment(.center)
						.opacity(0.5)
					HStack
					{
						URLImage(url: URL(string: "https://parsecusercontent.com/cors-resize-image/w=48,h=48,fit=crop,background=white,q=90,f=jpeg/avatars/\(String(user.id))/avatar"),
						         output:
						         {
						         	$0
						         		.resizable()
						         		.aspectRatio(contentMode: .fit)
						         		.frame(width: 48, height: 48)
						         		.cornerRadius(6)
						         },
						         placeholder:
						         {
						         	Image("IconTransparent")
						         		.resizable()
						         		.aspectRatio(contentMode: .fit)
						         		.frame(width: 48, height: 48)
						         		.background(Rectangle().fill(Color("BackgroundPrompt")))
						         		.cornerRadius(6)
						         })
						Text("\(user.username)#\(String(user.id))")
							.font(.system(size: 16, weight: .medium))
							.multilineTextAlignment(.center)
						Spacer()
					}
					.padding(8)
					.background(Color("BackgroundCard"))
					.cornerRadius(12)
				}
				if friends.count > 0
				{
					Text("Friends")
						.multilineTextAlignment(.center)
						.opacity(0.5)
					ForEach(friends)
					{ i in
						HStack
						{
							URLImage(url: URL(string: "https://parsecusercontent.com/cors-resize-image/w=48,h=48,fit=crop,background=white,q=90,f=jpeg/avatars/\(String(i.id))/avatar"),
							         output:
							         {
							         	$0
							         		.resizable()
							         		.aspectRatio(contentMode: .fit)
							         		.frame(width: 48, height: 48)
							         		.cornerRadius(6)
							         },
							         placeholder:
							         {
							         	Image("IconTransparent")
							         		.resizable()
							         		.aspectRatio(contentMode: .fit)
							         		.frame(width: 48, height: 48)
							         		.background(Rectangle().fill(Color("BackgroundPrompt")))
							         		.cornerRadius(6)
							         })
							Text("\(i.username)#\(String(i.id))")
								.font(.system(size: 16, weight: .medium))
								.multilineTextAlignment(.center)
							Spacer()
//										Button(action:{ }, label:{ Image(systemName:"ellipsis.circle.fill") })
//											.font(.system(size:20))
//											.foregroundColor(Color("AccentColor"))
//											.padding(8)
						}
						.padding(8)
						.background(Color("BackgroundCard"))
						.cornerRadius(12)
					}
				}
			}
			.padding()
		}
	}

	var body: some View
	{
		TabView
		{
			Tab("Hosts", systemImage: "desktopcomputer")
			{
				NavigationStack
				{
					hostsPage
						.toolbar
						{
							ToolbarItem(placement: .cancellationAction)
							{
								Button(action: { showLogoutAlert = true }, label: { Image("SymbolExit").scaleEffect(x: -1) })
									.padding()
							}
							ToolbarItem(placement: .largeTitle)
							{
								HStack
								{
									Image(systemName: "arrow.clockwise")
										.padding(4)
										.opacity(0)

									Text(hostCountStr)
										.multilineTextAlignment(.center)
										.foregroundColor(Color("Foreground"))
										.font(.system(size: 20, weight: .medium))
								}
							}
							ToolbarItem(placement: .topBarTrailing)
							{
								Button(action: { inSettings = true }, label: { Image(systemName: "gear") })
									.padding()
							}
						}
				}
			}
			Tab("Friends", systemImage: "person.2.fill")
			{
				NavigationStack
				{
					friendsPage
						.toolbar
						{
							ToolbarItem(placement: .cancellationAction)
							{
								Button(action: { showLogoutAlert = true }, label: { Image("SymbolExit").scaleEffect(x: -1) })
									.padding()
							}
							ToolbarItem(placement: .largeTitle)
							{
								Text(friendCountStr)
									.multilineTextAlignment(.center)
									.foregroundColor(Color("Foreground"))
									.font(.system(size: 20, weight: .medium))
							}
							ToolbarItem(placement: .topBarTrailing)
							{
								Button(action: { inSettings = true }, label: { Image(systemName: "gear") })
									.padding()
							}
						}
				}
			}
		}
		.onAppear(perform: initView)
		.sheet(isPresented: $inSettings, content: {
			SettingsView()
		})
		.alert(isPresented: $showBaseAlert)
		{
			Alert(title: Text(baseAlertText))
		}
		.alert(isPresented: $showLogoutAlert)
		{
			Alert(title: Text("Are you sure you want to logout?"), primaryButton: .destructive(Text("Logout"), action: logout), secondaryButton: .cancel(Text("Cancel")))
		}

//		// Loading elements
//		if isConnecting
//		{
//			ZStack
//			{
//				Rectangle() // Darken background
//					.fill(Color.black)
//					.opacity(0.5)
//					.edgesIgnoringSafeArea(.all)
//				VStack
//				{
//					ActivityIndicator(isAnimating: $isConnecting, style: .large, tint: .white)
//						.padding()
//					Text("Requesting connection to \(connectingToName)...")
//						.multilineTextAlignment(.center)
//					Button(action: cancelConnection)
//					{
//						ZStack
//						{
//							Rectangle()
//								.fill(Color("BackgroundButton"))
//								.cornerRadius(8)
//							Text("Cancel")
//								.foregroundColor(.red)
//						}
//					}
//					.frame(maxWidth: 100, maxHeight: 48)
//				}
//				.padding()
//				.background(Rectangle().fill(Color("BackgroundPrompt")))
//				.cornerRadius(8)
//				.padding()
//			}
//		}
//		if isRefreshing
//		{
//			ZStack
//			{
//				Rectangle() // Darken background
//					.fill(Color.black)
//					.opacity(0.5)
//					.edgesIgnoringSafeArea(.all)
//				VStack
//				{
//					ActivityIndicator(isAnimating: $isRefreshing, style: .large, tint: .white)
//						.padding()
//					Text("Refreshing hosts...")
//						.multilineTextAlignment(.center)
//				}
//				.padding()
//				.background(Rectangle().fill(Color("BackgroundPrompt")))
//				.cornerRadius(8)
//				.padding()
//			}
//		}
	}

	func initView()
	{
		refreshHosts()
		refreshSelf()
		refreshFriends()
	}

	func refreshHosts()
	{
		withAnimation
		{
			isRefreshing = true

			let clinfo = NetworkHandler.clinfo
			if clinfo == nil
			{
				isRefreshing = false
				baseAlertText = "Error gathering hosts: Invalid session"
				showBaseAlert = true
				return
			}

			let apiURL = URL(string: "https://kessel-api.parsec.app/v2/hosts?mode=desktop&public=false")!

			var request = URLRequest(url: apiURL)
			request.httpMethod = "GET"
			request.setValue("application/json", forHTTPHeaderField: "Content-Type")
			request.setValue("Bearer \(clinfo!.session_id)", forHTTPHeaderField: "Authorization")
			request.setValue("parsec/150-93b Windows/11 libmatoya/4.0", forHTTPHeaderField: "User-Agent")

			let task = URLSession.shared.dataTask(with: request)
			{ data, response, _ in
				if let data = data
				{
					let statusCode: Int = (response as! HTTPURLResponse).statusCode
					let decoder = JSONDecoder()

					if statusCode == 200 // 200 OK
					{
						let info: HostInfoList = try! decoder.decode(HostInfoList.self, from: data)
						hosts.removeAll()
						if let datas = info.data
						{
							for h in datas
							{
								hosts.append(IdentifiableHostInfo(id: h.peer_id, hostname: h.name, user: h.user, connections: h.players))
							}
						}

						var grammar = "hosts"
						if hosts.count == 1
						{
							grammar = "host"
						}

						hostCountStr = "\(hosts.count) \(grammar)"

						let formatter = DateFormatter()
						formatter.dateFormat = "M/d/yyyy h:mm a"
						refreshTime = "Last refreshed at \(formatter.string(from: Date()))"
					}
					else if statusCode == 403 // 403 Forbidden
					{
						let info: ErrorInfo = try! decoder.decode(ErrorInfo.self, from: data)

						baseAlertText = "Error gathering hosts: \(info.error)"
						showBaseAlert = true
					}
				}

				isRefreshing = false
			}
			task.resume()
		}
	}

	func refreshSelf()
	{
		withAnimation
		{
			let clinfo = NetworkHandler.clinfo
			if clinfo == nil
			{
				return
			}

			let apiURL = URL(string: "https://kessel-api.parsec.app/me")!

			var request = URLRequest(url: apiURL)
			request.httpMethod = "GET"
			request.setValue("application/json", forHTTPHeaderField: "Content-Type")
			request.setValue("Bearer \(clinfo!.session_id)", forHTTPHeaderField: "Authorization")
			request.setValue("parsec/150-93b Windows/11 libmatoya/4.0", forHTTPHeaderField: "User-Agent")

			let task = URLSession.shared.dataTask(with: request)
			{ data, response, _ in
				if let data = data
				{
					let statusCode: Int = (response as! HTTPURLResponse).statusCode
					let decoder = JSONDecoder()

					if statusCode == 200 // 200 OK
					{
						let data: SelfInfoData = try! decoder.decode(SelfInfo.self, from: data).data
						userInfo = IdentifiableUserInfo(id: data.id, username: data.name)
					}
					else
					{
						let info: ErrorInfo = try! decoder.decode(ErrorInfo.self, from: data)

						baseAlertText = "Error gathering user info: \(info.error)"
						showBaseAlert = true
					}
				}
			}
			task.resume()
		}
	}

	func refreshFriends()
	{
		withAnimation
		{
			let clinfo = NetworkHandler.clinfo
			if clinfo == nil
			{
				return
			}

			let apiURL = URL(string: "https://kessel-api.parsec.app/friendships")!

			var request = URLRequest(url: apiURL)
			request.httpMethod = "GET"
			request.setValue("application/json", forHTTPHeaderField: "Content-Type")
			request.setValue("Bearer \(clinfo!.session_id)", forHTTPHeaderField: "Authorization")
			request.setValue("parsec/150-93b Windows/11 libmatoya/4.0", forHTTPHeaderField: "User-Agent")

			let task = URLSession.shared.dataTask(with: request)
			{ data, response, _ in
				if let data = data
				{
					let statusCode: Int = (response as! HTTPURLResponse).statusCode
					let decoder = JSONDecoder()

					print("/friendships: \(statusCode)")
					print(String(data: data, encoding: .utf8)!)

					if statusCode == 200 // 200 OK
					{
						let info: FriendInfoList = try! decoder.decode(FriendInfoList.self, from: data)
						friends.removeAll()
						if let datas = info.data
						{
							for f in datas
							{
								friends.append(IdentifiableUserInfo(id: f.user_id, username: f.user_name))
							}
						}

						var grammar = "friends"
						if friends.count == 1
						{
							grammar = "friend"
						}

						friendCountStr = "\(friends.count) \(grammar)"
					}
					else
					{
						let info: ErrorInfo = try! decoder.decode(ErrorInfo.self, from: data)

						baseAlertText = "Error gathering friends: \(info.error)"
						showBaseAlert = true
					}
				}

				isRefreshing = false
			}
			task.resume()
		}
	}

	func connectTo(_ who: IdentifiableHostInfo)
	{
		CParsec.initialize()
		connectingToName = who.hostname
		withAnimation { isConnecting = true }

		var status = CParsec.connect(who.id)

		// Polling status
		pollTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true)
		{ timer in
			status = CParsec.getStatus()

			if status == PARSEC_CONNECTING { return } // wait

			withAnimation { isConnecting = false }

			if status == PARSEC_OK
			{
				if let c = controller
				{
					c.setView(.parsec)
				}
			}
			else
			{
				baseAlertText = "Error connecting to host (code \(status.rawValue))"
				showBaseAlert = true
			}

			timer.invalidate()
		}
	}

	func cancelConnection()
	{
		withAnimation { isConnecting = false }

		CParsec.disconnect()

		pollTimer!.invalidate()
	}

	func logout()
	{
		removeFromKeychain(key: GLBDataModel.shared.SessionKeyChainKey)
		NetworkHandler.clinfo = nil
		if let c = controller
		{
			c.setView(.login)
		}
	}

	func removeFromKeychain(key: String)
	{
		let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword, kSecAttrAccount as String: key]
		let status = SecItemDelete(query as CFDictionary)
		if status == errSecSuccess
		{
			print("Successfully removed data from keychain.")
		}
	}
}

struct MainView_Previews: PreviewProvider
{
	static var previews: some View
	{
		MainView(nil)
	}
}

struct IdentifiableHostInfo: Identifiable
{
	var id: String // Peer ID
	var hostname: String // Computer's Display Name
	var user: UserInfo // User Data
	var connections: Int // User's Connected To This Host
}

struct IdentifiableUserInfo: Identifiable
{
	var id: Int // User ID
	var username: String // User Display Name
}

private enum Page
{
	case hosts
	case friends
}
