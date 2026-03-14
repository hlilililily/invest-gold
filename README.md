# 黄金管家 (GoldTracker)

一款 iOS / macOS 通用的黄金投资理财 App，基于 **加权平均成本法 (WAC)** 精确计算买卖盈亏。

## 核心功能

- **多策略管理** — 分别追踪长线、短线、波段等不同投资策略
- **加权平均成本法** — 每次买入自动摊薄均价，卖出按持仓均价计算真实盈亏
- **实时盈亏面板** — 已实现盈亏 + 浮动盈亏 + 总盈亏一目了然
- **收益计算器** — 独立模拟不同价位的买入卖出场景
- **交易记录** — 完整的交易流水，支持筛选与删除

## 计算逻辑说明

### 加权平均成本法 (Weighted Average Cost)

| 操作 | 公式 |
|------|------|
| **买入** | `新均价 = (持仓克数 × 旧均价 + 买入克数 × 买入价) / (持仓克数 + 买入克数)` |
| **卖出** | `已实现盈亏 = (卖出价 − 持仓均价) × 卖出克数`；均价不变 |
| **浮动盈亏** | `(市场价 − 持仓均价) × 持仓克数` |

### 示例验证

> 持有 100g 均价 ¥1100，买入 10g 均价 ¥1000，再以 ¥1100/g 卖出 10g

1. **买入后**: 均价 = (100×1100 + 10×1000) / 110 = **¥1090.91/g**
2. **卖出 10g@1100**: 盈亏 = (1100 − 1090.91) × 10 = **+¥90.91** （不是 ¥1000！）
3. **卖出后持仓**: 100g，均价 ¥1090.91

## 技术栈

| 技术 | 版本要求 |
|------|----------|
| SwiftUI | iOS 17+ / macOS 14+ |
| SwiftData | 持久化存储 |
| Swift Observation | `@Observable` 响应式状态管理 |

## 项目结构

```
GoldTracker/
├── GoldTracker.xcodeproj/      # Xcode 工程文件
├── GoldTracker/
│   ├── GoldTrackerApp.swift     # App 入口
│   ├── ContentView.swift        # 主视图 (TabView/NavigationSplitView)
│   ├── Models/
│   │   ├── Transaction.swift    # 交易数据模型 (SwiftData)
│   │   ├── Portfolio.swift      # 策略/组合模型 (SwiftData)
│   │   └── GoldCalculator.swift # WAC 计算引擎 (纯函数)
│   ├── ViewModels/
│   │   └── PortfolioViewModel.swift  # 业务逻辑层
│   ├── Views/
│   │   ├── DashboardView.swift       # 首页概览
│   │   ├── AddTransactionView.swift  # 添加交易 (含实时预览)
│   │   ├── TransactionListView.swift # 交易记录列表
│   │   ├── PortfolioManageView.swift # 策略管理 + 全局汇总
│   │   ├── CalculatorView.swift      # 独立收益计算器
│   │   └── Components/
│   │       ├── StatCard.swift        # 统计卡片
│   │       ├── TransactionRow.swift  # 交易行
│   │       └── ProfitText.swift      # 盈亏文字 (自动着色)
│   └── Utils/
│       └── Formatters.swift          # 格式化工具
└── GoldTrackerTests/
    └── GoldCalculatorTests.swift     # 计算引擎单元测试
```

## 快速开始

1. 用 Xcode 15+ 打开 `GoldTracker.xcodeproj`
2. 选择 iOS Simulator 或 macOS 作为运行目标
3. `Cmd + R` 运行

## App 界面

### iOS — 底部 Tab 导航
- 概览 / 交易 / 计算器 / 策略

### macOS — 侧边栏导航
- 左侧 Sidebar + 右侧 Detail 布局

## 使用说明

1. **设置策略**: 在"策略"页面创建不同的投资策略（如长线、短线）
2. **记录交易**: 点击 + 按钮添加买入/卖出记录，实时预览均价变化和盈亏
3. **查看盈亏**: 在"概览"页面输入当前市场金价，查看浮动盈亏
4. **模拟计算**: 使用"计算器"模拟不同价位的操作效果
