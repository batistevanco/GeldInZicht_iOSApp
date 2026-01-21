import SwiftUI

struct HelpView: View {

    @State private var showFullHelp = false

    var body: some View {
        List {

            // MARK: - Welcome
            Section(header: Text("Welkom")) {
                Text("Met deze app beheer je je budget, rekeningen en spaarpotjes.")
            }

            // MARK: - How it works (Expandable)
            Section(header: Text("Hoe werkt de app?")) {
                DisclosureGroup(
                    "Volledige uitleg bekijken",
                    isExpanded: $showFullHelp
                ) {
                    VStack(alignment: .leading, spacing: 12) {

                        Group {
                            Text("Overzicht")
                                .font(.headline)

                            Text("""
Deze app helpt je om inzicht te krijgen in je geld. Je kan inkomsten en uitgaven registreren, geld verdelen over rekeningen en spaarpotjes, en overzichten bekijken per week, maand of jaar.
""")
                        }

                        Group {
                            Text("Resterende functies")
                                .font(.headline)

                            Text("""
• Inkomsten en uitgaven toevoegen
• Terugkerende transacties instellen
• Meerdere rekeningen beheren
• Spaarpotjes gebruiken voor doelen
• Overboeken tussen rekeningen
• Net worth (totaal vermogen) bekijken
""")
                        }

                        Group {
                            Text("Transacties beheren")
                                .font(.headline)

                            Text("""
• Tik op de + knop om een nieuwe transactie toe te voegen
• Tik op een transactie om details te bekijken
• Gebruik 'Bewerken' om een transactie aan te passen
• Swipe een transactie (indien beschikbaar) om te verwijderen
""")
                        }

                        Group {
                            Text("Rekeningen")
                                .font(.headline)

                            Text("""
• Maak meerdere rekeningen aan (zichtrekening, spaarrekening, cash, …)
• Elke rekening heeft een startsaldo
• Swipe een rekening naar links om deze te verwijderen
• Verwijderde rekeningen verdwijnen volledig uit de app
""")
                        }

                        Group {
                            Text("Spaarpotjes")
                                .font(.headline)

                            Text("""
• Gebruik spaarpotjes voor specifieke doelen (bv. vakantie, buffer)
                            • Je kan geld storten of opnemen vanuit een spaarpot
• Swipe een spaarpotje naar links om het te verwijderen
""")
                        }

                        Group {
                            Text("Categorieën")
                                .font(.headline)

                            Text("""
• Standaardcategorieën zijn vast en kunnen niet worden verwijderd
• Eigen categorieën kan je zelf aanmaken
• Om een categorie te verwijderen:
  1. Ga naar Instellingen
  2. Kies 'Mijn categorieën beheren'
  3. Swipe de categorie naar links
  4. Tik op 'Verwijder'
""")
                        }

                        Group {
                            Text("Gegevens & privacy")
                                .font(.headline)

                            Text("""
• Alle gegevens blijven lokaal op je toestel
• Er is geen account en geen cloud
• Verwijder je de app, dan verdwijnen alle gegevens
""")
                        }
                    }
                    .padding(.vertical, 8)
                }
            }

            // MARK: - Settings
            Section(header: Text("Instellingen")) {
                NavigationLink("Instellingen") {
                    SettingsView()
                }
            }

            // MARK: - Privacy
            Section(header: Text("Privacy")) {
                if let url = URL(string: "https://www.vancoillieithulp.be/privacyPolicyGeldInZicht.html") {
                    Link("Bekijk privacybeleid", destination: url)
                } else {
                    Text("Privacybeleid URL ongeldig")
                        .foregroundColor(.secondary)
                }
            }

            // MARK: - App info
            Section(header: Text("App info")) {
                HStack {
                    Text("Versie")
                    Spacer()
                    Text(appVersion)
                        .foregroundColor(.secondary)
                }

                HStack {
                    Text("Build")
                    Spacer()
                    Text(buildNumber)
                        .foregroundColor(.secondary)
                }
            }

            // MARK: - Info
            Section {
                Text("Offline • Geen account • Privacyvriendelijk")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle("Hulp")
    }

    // MARK: - Version helpers

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
    }

    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "—"
    }
}
