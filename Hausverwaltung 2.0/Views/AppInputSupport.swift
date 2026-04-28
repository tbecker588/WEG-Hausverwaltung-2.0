import SwiftUI
import UIKit

enum AppInputKind {
    case organizationName
    case personName
    case givenName
    case familyName
    case fullAddress
    case streetAddress
    case postalCode
    case city
    case phone
    case email
}

extension View {
    @ViewBuilder
    func appInputTraits(_ kind: AppInputKind) -> some View {
        switch kind {
        case .organizationName:
            self
                .textContentType(.organizationName)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
        case .personName:
            self
                .textContentType(.name)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
        case .givenName:
            self
                .textContentType(.givenName)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
        case .familyName:
            self
                .textContentType(.familyName)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
        case .fullAddress:
            self
                .textContentType(.fullStreetAddress)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
        case .streetAddress:
            self
                .textContentType(.streetAddressLine1)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
        case .postalCode:
            self
                .textContentType(.postalCode)
                .keyboardType(.numberPad)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
        case .city:
            self
                .textContentType(.addressCity)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
        case .phone:
            self
                .textContentType(.telephoneNumber)
                .keyboardType(.phonePad)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
        case .email:
            self
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
        }
    }

    func appKeyboardToolbar() -> some View {
        modifier(AppKeyboardToolbarModifier())
    }
}

private struct AppKeyboardToolbarModifier: ViewModifier {
    func body(content: Content) -> some View {
        content.toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Fertig") {
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
            }
        }
    }
}