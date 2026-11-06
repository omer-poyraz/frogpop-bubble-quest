# Google Play - Data safety answers (draft, matches the code)

Update when the AdMob SDK is added. Current plugin-less build collects nothing.

| Question | Plugin-less build | Build with AdMob + Billing |
|---|---|---|
| Does the app collect or share user data? | No | Yes (Advertising ID, approximate location from IP, app interactions / diagnostics via AdMob) |
| Data collected | none | Device or other IDs (Advertising ID) - ads/marketing, analytics (by Google); App activity - ad interactions |
| Data shared | none | With Google (ads provider) |
| Purpose | - | Advertising or marketing, fraud prevention |
| Collected data processed ephemerally? | - | No (per Google's policy) |
| Is data encrypted in transit? | n/a | Yes (HTTPS, by SDK) |
| Can users request deletion? | Local data: Settings > Delete my progress / uninstall | Same + reset Advertising ID in device settings |
| Payments | handled by Google Play | handled by Google Play |
| Target audience | 13+ / general, not child-directed | same |
| Account creation | none | none |
| Privacy policy URL | https://omer-poyraz.github.io/frogpop-bubble-quest/privacy-policy/ | same |

Ads declaration: contains ads = **Yes** (once AdMob is enabled).
