//
//  ProfileImage.swift
//  OpenParsec
//
//  Created by Kyle Giammarco on 2026-01-04.
//

import SwiftUI

struct ProfileImage: View
{
	let imageUrl: URL?

	@State var size: CGFloat

	var body: some View
	{
		VStack
		{
			if let imageUrl
			{
				URLImage(url: imageUrl,
				         output:
				         {
				         	$0
				         		.resizable()
				         		.aspectRatio(contentMode: .fit)
				         },
				         placeholder:
				         {
				         	Image("IconTransparent")
				         		.resizable()
				         		.aspectRatio(contentMode: .fit)
				         })
			}
			else
			{
				Image("IconTransparent")
					.resizable()
					.aspectRatio(contentMode: .fit)
			}
		}
		.frame(width: size, height: size)
		.background(Rectangle().fill(Color("BackgroundPrompt")))
		.cornerRadius(size / 8)
	}
}
