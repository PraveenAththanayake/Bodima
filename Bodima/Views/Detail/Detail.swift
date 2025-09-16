import SwiftUI
import UIKit
import Foundation

struct DetailView: View {
    let habitation: EnhancedHabitationData
    let locationData: LocationData?
    let featureData: HabitationFeatureData?
    @State private var isBookmarked = false
    @State private var isLiked = false
    @State private var likesCount = 24
    @State private var isFollowing = false
    @State private var navigateToReserve = false
    @State private var showReservationDialog = false
    @State private var navigateToHome = false
    @Environment(\.presentationMode) var presentationMode
    
    private var fullAddress: String {
        guard let location = locationData else { 
            if let user = habitation.user {
                return "\(user.city), \(user.district)" 
            } else {
                return "Unknown location"
            }
        }
        return "\(location.addressNo), \(location.addressLine01), \(location.city), \(location.district)"
    }
    
    private var formattedTime: String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        guard let date = formatter.date(from: habitation.createdAt) else { return "now" }
        
        let now = Date()
        let calendar = Calendar.current
        let components = calendar.dateComponents([.minute, .hour, .day], from: date, to: now)
        
        if let day = components.day, day > 0 {
            return "\(day)d"
        } else if let hour = components.hour, hour > 0 {
            return "\(hour)h"
        } else if let minute = components.minute, minute > 0 {
            return "\(minute)m"
        } else {
            return "now"
        }
    }
    
    private var userInitials: String {
        if let user = habitation.user {
            return String(user.firstName.prefix(1)) + String(user.lastName.prefix(1))
        } else {
            return "?"
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    
                    headerView
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(AppColors.background)
                    
                    contentCard
                        .padding(.horizontal, 16)
                    
                    if featureData != nil {
                        amenitiesSection
                            .padding(.horizontal, 16)
                    }
                    
                    pricingSection
                        .padding(.horizontal, 16)
                }
                .padding(.bottom, 80)
            }
            .background(AppColors.background)
            .navigationBarHidden(true)
            .navigationDestination(isPresented: $navigateToReserve) {
                ReserveView(
                    habitation: habitation,
                    locationData: locationData,
                    featureData: featureData
                )
            }
        }
        .overlay(
            Group {
                if showReservationDialog {
                    ReservationConfirmationDialog(
                        habitation: habitation,
                        onConfirm: {
                            showReservationDialog = false
                            navigateToReserve = true
                        },
                        onCancel: {
                            showReservationDialog = false
                        },
                        onExpired: {
                            showReservationDialog = false
                            navigateToHome = true
                        }
                    )
                    .animation(.spring(response: 0.5, dampingFraction: 0.8), value: showReservationDialog)
                }
            }
        )
        .onChange(of: navigateToHome) { shouldNavigateToHome in
            if shouldNavigateToHome {
                // Navigate back to home by dismissing the current view
                presentationMode.wrappedValue.dismiss()
            }
        }
    }
    
    private var headerView: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Bodima")
                    .font(.title2.bold())
                    .foregroundStyle(AppColors.foreground)
                
                Text("Habitation Info")
                    .font(.caption)
                    .foregroundStyle(AppColors.mutedForeground)
            }
            
            Spacer()
            
            Button(action: {
                presentationMode.wrappedValue.dismiss()
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(AppColors.foreground)
                    .frame(width: 44, height: 44)
                    .background(AppColors.input)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(AppColors.border, lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Back")
        }
    }
    
    private var contentCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .center, spacing: 12) {
                Circle()
                    .fill(AppColors.input)
                    .frame(width: 48, height: 48)
                    .overlay(
                        Text(userInitials)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(AppColors.foreground)
                    )
                    .overlay(
                        Circle()
                            .stroke(AppColors.border, lineWidth: 1)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(habitation.userFullName)
                    .font(.subheadline.bold())
                    .foregroundStyle(AppColors.foreground)
                
                if let user = habitation.user {
                    Text("@\(user.auth) • \(formattedTime)")
                        .font(.caption)
                        .foregroundStyle(AppColors.mutedForeground)
                } else {
                    Text("• \(formattedTime)")
                        .font(.caption)
                        .foregroundStyle(AppColors.mutedForeground)
                }
                }
                
                Spacer()
                
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        isFollowing.toggle()
                    }
                }) {
                    Text(isFollowing ? "Following" : "Follow")
                        .font(.subheadline.bold())
                        .foregroundStyle(isFollowing ? AppColors.foreground : .white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(isFollowing ? AppColors.input : AppColors.primary)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(isFollowing ? AppColors.border : AppColors.primary, lineWidth: 1)
                                )
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel(isFollowing ? "Unfollow" : "Follow")
                
                Button(action: {
                }) {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(AppColors.mutedForeground)
                        .rotationEffect(.degrees(90))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("More options")
            }
            
            habitationImageView
            
            HStack(spacing: 16) {
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        isLiked.toggle()
                        likesCount += isLiked ? 1 : -1
                    }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: isLiked ? "heart.fill" : "heart")
                            .font(.system(size: 20))
                            .foregroundStyle(isLiked ? AppColors.primary : AppColors.mutedForeground)
                            .scaleEffect(isLiked ? 1.1 : 1.0)
                        
                        if likesCount > 0 {
                            Text("\(likesCount)")
                                .font(.subheadline.bold())
                                .foregroundStyle(AppColors.foreground)
                        }
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel(isLiked ? "Unlike" : "Like")
                
                Button(action: {
                }) {
                    Image(systemName: "paperplane")
                        .font(.system(size: 20))
                        .foregroundStyle(AppColors.mutedForeground)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Share")
                
                Spacer()
                
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        isBookmarked.toggle()
                    }
                }) {
                    Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                        .font(.system(size: 20))
                        .foregroundStyle(isBookmarked ? AppColors.primary : AppColors.mutedForeground)
                        .scaleEffect(isBookmarked ? 1.1 : 1.0)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(isBookmarked ? "Remove bookmark" : "Bookmark")
            }
            
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(habitation.name)
                        .font(.title3.bold())
                        .foregroundStyle(AppColors.foreground)
                    
                    Spacer()
                    
                    Text(habitation.type)
                        .font(.caption.bold())
                        .foregroundStyle(AppColors.primary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(AppColors.primary.opacity(0.1))
                        .cornerRadius(12)
                }
                
                Text(habitation.description)
                    .font(.subheadline)
                    .foregroundStyle(AppColors.foreground)
                    .lineLimit(nil)
                    .multilineTextAlignment(.leading)
                
                Text(fullAddress)
                    .font(.subheadline)
                    .foregroundStyle(AppColors.primary)
                
                HStack(spacing: 8) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(.yellow)
                    Text("4.5")
                        .font(.subheadline)
                        .foregroundStyle(AppColors.foreground)
                    Text("(235)")
                        .font(.subheadline)
                        .foregroundStyle(AppColors.mutedForeground)
                    
                    Spacer()
                    
                    if habitation.isReserved {
                        Text("Reserved")
                            .font(.caption.bold())
                            .foregroundStyle(.red)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(8)
                    } else {
                        Text("Available")
                            .font(.caption.bold())
                            .foregroundStyle(.green)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(8)
                    }
                }
                
                HStack(spacing: 16) {
                    Button(action: {
                    }) {
                        Image(systemName: "phone")
                            .font(.system(size: 18))
                            .foregroundStyle(AppColors.mutedForeground)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Call")
                    
                    Button(action: {
                    }) {
                        Image(systemName: "envelope")
                            .font(.system(size: 18))
                            .foregroundStyle(AppColors.mutedForeground)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Email")
                    
                 
                    .buttonStyle(.plain)
                    .accessibilityLabel("Message")
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppColors.background)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(AppColors.border, lineWidth: 1)
                )
        )
        .shadow(color: AppColors.border.opacity(0.1), radius: 8, x: 0, y: 4)
    }
    
    private var habitationImageView: some View {
        Group {
            if let pictures = habitation.pictures, !pictures.isEmpty, let firstPicture = pictures.first {
                CachedImage(url: firstPicture.pictureUrl, contentMode: .fill) {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(AppColors.input)
                        .frame(width: 350, height: 280)
                        .overlay(
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                        )
                }
                .frame(width: 350, height: 280)
                .clipped()
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(AppColors.border, lineWidth: 1)
                )
            } else {
                RoundedRectangle(cornerRadius: 16)
                    .fill(AppColors.input)
                    .frame(width: 350, height: 280)
                    .overlay(
                        Image(systemName: "photo")
                            .font(.system(size: 44, weight: .light))
                            .foregroundStyle(AppColors.mutedForeground)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(AppColors.border, lineWidth: 1)
                    )
            }
        }
    }
    
    private var amenitiesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Amenities")
                .font(.title3.bold())
                .foregroundStyle(AppColors.foreground)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 12) {
                if let feature = featureData {
                    AmenityView(icon: "square.fill", text: "\(feature.sqft) sq ft")
                    AmenityView(icon: "person.2.fill", text: feature.familyType)
                    AmenityView(icon: "bed.double.fill", text: "\(feature.windowsCount) Windows")
                    
                    if feature.smallBedCount > 0 {
                        AmenityView(icon: "bed.double.fill", text: "\(feature.smallBedCount) Small bed\(feature.smallBedCount > 1 ? "s" : "")")
                    }
                    
                    if feature.largeBedCount > 0 {
                        AmenityView(icon: "bed.double.fill", text: "\(feature.largeBedCount) Large bed\(feature.largeBedCount > 1 ? "s" : "")")
                    }
                    
                    if feature.chairCount > 0 {
                        AmenityView(icon: "chair.fill", text: "\(feature.chairCount) Chair\(feature.chairCount > 1 ? "s" : "")")
                    }
                    
                    if feature.tableCount > 0 {
                        AmenityView(icon: "table.fill", text: "\(feature.tableCount) Table\(feature.tableCount > 1 ? "s" : "")")
                    }
                    
                    if feature.isElectricityAvailable {
                        AmenityView(icon: "bolt.fill", text: "Electricity")
                    }
                    
                    if feature.isWachineMachineAvailable {
                        AmenityView(icon: "washer.fill", text: "Washing machine")
                    }
                    
                    if feature.isWaterAvailable {
                        AmenityView(icon: "drop.fill", text: "Water")
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppColors.background)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(AppColors.border, lineWidth: 1)
                )
        )
        .shadow(color: AppColors.border.opacity(0.1), radius: 8, x: 0, y: 4)
    }
    
    private var pricingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("LKR \(habitation.price).00")
                .font(.title2.bold())
                .foregroundStyle(AppColors.foreground)
            
            Text("Monthly rent")
                .font(.subheadline)
                .foregroundStyle(AppColors.mutedForeground)
            
            Button(action: {
                showReservationDialog = true
            }) {
                Text("Reserve Now")
                    .font(.subheadline.bold())
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(habitation.isReserved ? AppColors.mutedForeground : AppColors.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .buttonStyle(.plain)
            .disabled(habitation.isReserved)
            .accessibilityLabel(habitation.isReserved ? "Property Already Reserved" : "Reserve Now")
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppColors.background)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(AppColors.border, lineWidth: 1)
                )
        )
        .shadow(color: AppColors.border.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}

struct AmenityView: View {
    let icon: String
    let text: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(AppColors.mutedForeground)
            
            Text(text)
                .font(.caption)
                .foregroundStyle(AppColors.foreground)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AppColors.input)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(AppColors.border, lineWidth: 1)
                )
        )
    }
}
