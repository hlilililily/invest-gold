import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = PortfolioViewModel()
    @State private var showAddTransaction = false
    @State private var selectedTab: Tab = .dashboard

    enum Tab: String, CaseIterable {
        case dashboard = "概览"
        case transactions = "交易"
        case calculator = "计算器"
        case portfolios = "策略"

        var icon: String {
            switch self {
            case .dashboard:    return "chart.pie.fill"
            case .transactions: return "list.bullet.rectangle.fill"
            case .calculator:   return "function"
            case .portfolios:   return "folder.fill"
            }
        }
    }

    var body: some View {
        #if os(iOS)
        iOSLayout
        #else
        macOSLayout
        #endif
    }

    // MARK: - iOS

    private var iOSLayout: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                DashboardView()
                    .toolbar {
                        ToolbarItem(placement: .primaryAction) { addButton }
                    }
            }
            .tabItem {
                Label(Tab.dashboard.rawValue, systemImage: Tab.dashboard.icon)
            }
            .tag(Tab.dashboard)

            NavigationStack {
                TransactionListView()
                    .toolbar {
                        ToolbarItem(placement: .primaryAction) { addButton }
                    }
            }
            .tabItem {
                Label(Tab.transactions.rawValue, systemImage: Tab.transactions.icon)
            }
            .tag(Tab.transactions)

            NavigationStack {
                CalculatorView()
            }
            .tabItem {
                Label(Tab.calculator.rawValue, systemImage: Tab.calculator.icon)
            }
            .tag(Tab.calculator)

            NavigationStack {
                PortfolioManageView()
            }
            .tabItem {
                Label(Tab.portfolios.rawValue, systemImage: Tab.portfolios.icon)
            }
            .tag(Tab.portfolios)
        }
        .tint(Color("BrandGold"))
        .environment(viewModel)
        .sheet(isPresented: $showAddTransaction) {
            AddTransactionView()
                .environment(viewModel)
        }
        .onAppear {
            viewModel.setup(modelContext: modelContext)
        }
    }

    // MARK: - macOS

    private var optionalTabBinding: Binding<Tab?> {
        Binding<Tab?>(
            get: { selectedTab },
            set: { if let tab = $0 { selectedTab = tab } }
        )
    }

    private var macOSLayout: some View {
        NavigationSplitView {
            List(selection: optionalTabBinding) {
                Section {
                    ForEach(Tab.allCases, id: \.self) { tab in
                        Label(tab.rawValue, systemImage: tab.icon)
                            .tag(tab)
                    }
                }
            }
            .listStyle(.sidebar)
            .navigationSplitViewColumnWidth(min: 160, ideal: 190)
        } detail: {
            NavigationStack {
                switch selectedTab {
                case .dashboard:
                    DashboardView()
                case .transactions:
                    TransactionListView()
                case .calculator:
                    CalculatorView()
                case .portfolios:
                    PortfolioManageView()
                }
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) { addButton }
            }
        }
        .tint(Color("BrandGold"))
        .environment(viewModel)
        .sheet(isPresented: $showAddTransaction) {
            AddTransactionView()
                .environment(viewModel)
                .frame(minWidth: 460, minHeight: 560)
        }
        .onAppear {
            viewModel.setup(modelContext: modelContext)
        }
    }

    // MARK: - Shared

    private var addButton: some View {
        Button {
            showAddTransaction = true
        } label: {
            Image(systemName: "plus.circle.fill")
                .symbolRenderingMode(.hierarchical)
                .font(.title3)
        }
        .tint(Color("BrandGold"))
    }
}
