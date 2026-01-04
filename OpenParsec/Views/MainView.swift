import ButtonKit
import ParsecSDK
import SwiftUI

struct MainView: View
{
	var controller: ContentView?

	@State private var page: Page = .hosts

	// Host page vars

	@State var hosts: [IdentifiableHostInfo] = []
	@State var lastRefreshedAt: Date? = nil

	// Friend page vars

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
				if let lastRefreshedAt
				{
					Text("Last refreshed on \(lastRefreshedAt.formatted(date: .abbreviated, time: .complete))")
						.multilineTextAlignment(.center)
						.opacity(0.5)
				}

				ForEach(hosts)
				{ host in
					VStack
					{
						if host.connections > 0
						{
							HStack
							{
								Image(systemName: "person.fill")
								Text(String(host.connections))
									.font(.system(size: 16, weight: .medium))
								Spacer()
							}
						}
						ProfileImage(imageUrl: host.user.profileImage(), size: 64)

						Text(host.hostname)
							.font(.title)
							.multilineTextAlignment(.center)
						Text("\(host.user.name)#\(String(host.user.id))")
							.font(.callout)
							.foregroundStyle(.secondary)
							.multilineTextAlignment(.center)
						Button(action: { connectTo(host) })
						{
							Text("Connect")
						}
						.buttonStyle(.glassProminent)
					}
					.padding()
					.frame(maxWidth: 400)
					.background(.background.secondary)
					.clipShape(RoundedRectangle(cornerRadius: 16))
				}
			}
			.padding()
		}
		.refreshable(action: refreshHosts)
	}

	var friendsPage: some View
	{
		// Friends page
		List
		{
			if let user = userInfo
			{
				Section("You")
				{
					HStack
					{
						ProfileImage(imageUrl: user.profileImage(), size: 48)
						Text("\(user.username)#\(String(user.id))")
							.font(.system(size: 16, weight: .medium))
							.multilineTextAlignment(.center)
						Spacer()
					}
					.padding(8)
				}
			}
			if friends.count > 0
			{
				Section("Friends")
				{
					ForEach(friends)
					{ friend in
						HStack
						{
							ProfileImage(imageUrl: friend.profileImage(), size: 48)
							Text("\(friend.username)#\(String(friend.id))")
								.font(.system(size: 16, weight: .medium))
								.multilineTextAlignment(.center)
							Spacer()
						}
						.padding(8)
					}
				}
			}
		}
		.refreshable
		{
			await refreshFriends()
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
								Button(
									action: { showLogoutAlert = true },
									label: { Image(systemName: "rectangle.portrait.and.arrow.forward") }
								)
							}
							ToolbarItem(placement: .primaryAction)
							{
								AsyncButton
								{
									await refreshHosts()
								} label: {
									Image(systemName: "arrow.clockwise")
								}
							}
							ToolbarItem(placement: .topBarTrailing)
							{
								Button(action: { inSettings = true }, label: { Image(systemName: "gear") })
							}
						}
				}
				.task { await refreshHosts() }
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
								Button(
									action: { showLogoutAlert = true },
									label: { Image(systemName: "rectangle.portrait.and.arrow.forward") }
								)
							}
							ToolbarItem(placement: .primaryAction)
							{
								AsyncButton
								{
									await refreshFriends()
								} label: {
									Image(systemName: "arrow.clockwise")
								}
							}
							ToolbarItem(placement: .topBarTrailing)
							{
								Button(action: { inSettings = true }, label: { Image(systemName: "gear") })
							}
						}
				}
				.task { await refreshFriends() }
			}
		}
		.task { await refreshSelf() }
		.alert("Connecting", isPresented: $isConnecting, actions: {
			Button(role: .cancel)
			{
				cancelConnection()
			} label: {
				Text("Cancel")
			}
		}, message: {
			ProgressView()
		})
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
	}

	func refreshHosts() async
	{
		isRefreshing = true

		do
		{
			let hostInfo = try await NetworkHandler.getHosts()
			hosts.removeAll()

			hosts.append(contentsOf: hostInfo.data?.map
			{ h in
				IdentifiableHostInfo(id: h.peer_id, hostname: h.name, user: h.user, connections: h.players)
			} ?? [])

			lastRefreshedAt = Date()
		}
		catch let ParsecError.insufficentPermissions(error)
		{
			baseAlertText = error
			showBaseAlert = true
		}
		catch ParsecError.invalidSession
		{
			baseAlertText = "Error Gathering Hosts: Invalid session"
			showBaseAlert = true
		}
		catch
		{
			baseAlertText = "Error Occurred: \(error.localizedDescription)"
			showBaseAlert = true
		}

		isRefreshing = false
	}

	func refreshSelf() async
	{
		do
		{
			let selfInfo = try await NetworkHandler.getSelf()
			userInfo = IdentifiableUserInfo(id: selfInfo.id, username: selfInfo.name)
		}
		catch let ParsecError.insufficentPermissions(error)
		{
			baseAlertText = error
			showBaseAlert = true
		}
		catch ParsecError.invalidSession
		{
			baseAlertText = "Error Gathering User Info: Invalid session"
			showBaseAlert = true
		}
		catch
		{
			baseAlertText = "Error Occurred: \(error.localizedDescription)"
			showBaseAlert = true
		}
	}

	func refreshFriends() async
	{
		isRefreshing = true

		do
		{
			let friendInfo = try await NetworkHandler.getFriends()

			friends.removeAll()

			friends.append(contentsOf: friendInfo.data?.map
			{ friend in
				IdentifiableUserInfo(id: friend.user_id, username: friend.user_name)
			} ?? [])
		}
		catch let ParsecError.insufficentPermissions(error)
		{
			baseAlertText = error
			showBaseAlert = true
		}
		catch ParsecError.invalidSession
		{
			baseAlertText = "Error Gathering Friends: Invalid session"
			showBaseAlert = true
		}
		catch
		{
			baseAlertText = "Error Occurred: \(error.localizedDescription)"
			showBaseAlert = true
		}

		isRefreshing = false
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

	func profileImage() -> URL?
	{
		return URL(string: "https://parsecusercontent.com/cors-resize-image/w=64,h=64,fit=crop,background=white,q=90,f=jpeg/avatars/\(String(id))/avatar"
		)
	}
}

private enum Page
{
	case hosts
	case friends
}
