//
//  UserInfo+Parsec.swift
//  OpenParsec
//
//  Created by Kyle Giammarco on 2026-01-03.
//

import Foundation

extension UserInfo {
	func profileImage() -> URL? {
		return URL(
			string: "https://parsecusercontent.com/cors-resize-image/w=64,h=64,fit=crop,background=white,q=90,f=jpeg/avatars/\(String(self.id))/avatar"
		)
	}
}
