use_frameworks!
platform :ios, "13.2"

workspace "Currencies.xcworkspace"

abstract_target "Work" do
    pod "PromiseKit"

    target "CurrenciesApp" do
        project "CurrenciesApp/CurrenciesApp.xcodeproj"
    end
    target "Currencies" do
        project "Currencies/Currencies.xcodeproj"
    end
    target "CurrencyLayerAPI" do
        project "CurrencyLayerAPI/CurrencyLayerAPI.xcodeproj"
    end
end
