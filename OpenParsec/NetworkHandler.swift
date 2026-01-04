import Foundation

class NetworkHandler
{
	static var clinfo: ClientInfo?

	private static let hostUrl = "https://kessel-api.parsec.app/v2/hosts?mode=desktop&public=false"
	private static let friendsUrl = "https://kessel-api.parsec.app/friendships"
	private static let selfUrl = "https://kessel-api.parsec.app/me"

	private static let decoder: JSONDecoder = .init()

	static func getSelf() async throws -> SelfInfoData
	{
		do
		{
			guard let url = URL(string: selfUrl) else { throw ParsecError.invalidSession }

			let request = createRequest(for: url)
			let (data, response) = try await URLSession.shared.data(for: request)

			if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 403
			{
				let info: ErrorInfo = try! decoder.decode(ErrorInfo.self, from: data)
				throw ParsecError.insufficentPermissions(info.error)
			}

			return try decoder.decode(SelfInfo.self, from: data).data
		}
		catch
		{
			throw error
		}
	}

	static func getFriends() async throws -> FriendInfoList
	{
		do
		{
			guard let url = URL(string: friendsUrl) else { throw ParsecError.invalidSession }

			let request = createRequest(for: url)
			let (data, response) = try await URLSession.shared.data(for: request)

			if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 403
			{
				let info: ErrorInfo = try! decoder.decode(ErrorInfo.self, from: data)
				throw ParsecError.insufficentPermissions(info.error)
			}

			return try decoder.decode(FriendInfoList.self, from: data)
		}
		catch
		{
			throw error
		}
	}

	static func getHosts() async throws -> HostInfoList
	{
		do
		{
			guard let url = URL(string: hostUrl) else { throw ParsecError.invalidSession }

			let request = createRequest(for: url)
			let (data, response) = try await URLSession.shared.data(for: request)

			if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 403
			{
				let info: ErrorInfo = try! decoder.decode(ErrorInfo.self, from: data)
				throw ParsecError.insufficentPermissions(info.error)
			}

			return try decoder.decode(HostInfoList.self, from: data)
		}
		catch
		{
			throw error
		}
	}

	private static func createRequest(for url: URL, authenticated: Bool = true) -> URLRequest
	{
		var request = URLRequest(url: url)

		request.httpMethod = "GET"
		request.setValue("application/json", forHTTPHeaderField: "Content-Type")
		if authenticated
		{
			request.setValue("Bearer \(clinfo!.session_id)", forHTTPHeaderField: "Authorization")
		}
		request.setValue("parsec/150-93b Windows/11 libmatoya/4.0", forHTTPHeaderField: "User-Agent")
		return request
	}
}

enum ParsecError: Error
{
	case invalidSession
	case insufficentPermissions(String)
	case unknownError(String)
}

struct ErrorInfo: Decodable
{
	var error: String
//	var codes:Array
}

struct ClientInfo: Decodable
{
	var instance_id: String
	var user_id: Int
	var session_id: String
	var host_peer_id: String
}

struct UserInfo: Decodable
{
	var id: Int
	var name: String
	var warp: Bool
//	var external_id:String
//	var external_provider:String
	var team_id: String
}

struct HostInfo: Decodable
{
	var user: UserInfo
	var peer_id: String
	var game_id: String
	var description: String
	var max_players: Int
	var mode: String
	var name: String
	var event_name: String
	var players: Int
//	var public:Bool
	var guest_access: Bool
	var online: Bool
//	var self:Bool
	var build: String
}

struct HostInfoList: Decodable
{
	var data: [HostInfo]?
	var has_more: Bool
}

struct SelfInfoData: Decodable
{
	var id: Int
	var name: String
	var email: String
	var warp: Bool
	var staff: Bool
	var team_id: String
	var is_confirmed: Bool
	var team_is_active: Bool
	var is_saml: Bool
	var is_gateway_enabled: Bool
	var is_relay_enabled: Bool
	var has_tfa: Bool
//	var app_config:Any
	var cohort_channel: String
}

struct SelfInfo: Decodable
{
	var data: SelfInfoData
}

struct FriendInfo: Decodable
{
	var user_id: Int
	var user_name: String
}

struct FriendInfoList: Decodable
{
	var data: [FriendInfo]?
	var has_more: Bool
}
