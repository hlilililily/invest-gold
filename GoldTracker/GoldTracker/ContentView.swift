import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = PortfolioViewModel()
    @State private var showAddTransaction = false
    @State private var selectedTab: Tab = .dashboard

    enum Tab: String {
        case dashboard = "概览"
        case transactions = "交易"
        case calculator = "计算器"
        case portfolios = "策略"
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
                        ToolbarItem(placement: .primaryAction) {
                            addButton
                        }
                    }
            }
            .tabItem {
                Label("概览", systemImage: "chart.pie")
            }
            .tag(Tab.dashboard)

            NavigationStack {
                TransactionListView()
                    .toolbar {
                        ToolbarItem(placement: .primaryAction) {
                            addButton
                        }
                    }
            }
            .tabItem {
                Label("交易", systemImage: "list.bullet.rectangle")
            }
            .tag(Tab.transactions)

            NavigationStack {
                CalculatorView()
            }
            .tabItem {
                Label("计算器", systemImage: "function")
            }
            .tag(Tab.calculator)

            NavigationStack {
                PortfolioManageView()
            }
            .tabItem {
                Label("策略", systemImage: "folder")
            }
            .tag(Tab.portfolios)
        }
        .tint(.orange)
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

    private var macOSLayout: some View {
        NavigationSplitView {
            List(selection: $selectedTab) {
                Label("概览", systemImage: "chart.pie")
                    .tag(Tab.dashboard)
                Label("交易", systemImage: "list.bullet.rectangle")
                    .tag(Tab.transactions)
                Label("计算器", systemImage: "function")
                    .tag(Tab.calculator)
                Label("策略", systemImage: "folder")
                    .tag(Tab.portfolios)
            }
            .listStyle(.sidebar)
            .navigationSplitViewColumnWidth(min: 160, ideal: 180)
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
                ToolbarItem(placement: .primaryAction) {
                    addButton
                }
            }
        }
        .environment(viewModel)
        .sheet(isPresented: $showAddTransaction) {
            AddTransactionView()
                .environment(viewModel)
                .frame(minWidth: 420, minHeight: 500)
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
        .tint(.orange)
    }
}
