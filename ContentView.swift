import SwiftUI

private enum TaskCategory: String, CaseIterable, Identifiable, Codable {
    case work = "Work"
    case school = "School"
    case personal = "Personal"
    var id: String { rawValue }
    var tint: Color {
        switch self {
        case .work: Color(red: 0.84, green: 0.53, blue: 0.60)
        case .school: Color(red: 0.72, green: 0.82, blue: 0.63)
        case .personal: Color(red: 0.62, green: 0.74, blue: 0.82)
        }
    }
}

private struct TodoItem: Identifiable, Codable, Equatable {
    var id = UUID()
    var title: String
    var category: TaskCategory
    var day: String
    var isDone = false
}

struct ContentView: View {
    @State private var selectedDate = Date()
    @State private var newTitle = ""
    @State private var newCategory: TaskCategory = .school
    @State private var showDatePicker = false
    @State private var tasks: [TodoItem] = ContentView.loadTasks()
    @FocusState private var inputFocused: Bool

    private let ink = Color(red: 0.20, green: 0.19, blue: 0.18)
    private let completedTaskInk = Color(red: 0.39, green: 0.37, blue: 0.34)
    private let paper = Color(red: 0.985, green: 0.98, blue: 0.965)
    private var dayKey: String { Self.key(for: selectedDate) }
    private var todaysTasks: [TodoItem] { tasks.filter { $0.day == dayKey } }
    private var completedCount: Int { todaysTasks.filter(\.isDone).count }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider().overlay(Color.black.opacity(0.045))
            taskList
            addBar
        }
        .background(paper)
        .foregroundStyle(ink)
        .onChange(of: tasks) { _, _ in saveTasks() }
        .onAppear { seedIfNeeded() }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 19) {
            HStack(spacing: 11) {
                Button { shiftDate(-1) } label: { Image(systemName: "chevron.left") }
                    .buttonStyle(.plain).foregroundStyle(ink.opacity(0.68))
                Button { showDatePicker.toggle() } label: {
                    HStack(spacing: 7) {
                        Text(selectedDate.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day()))
                            .font(.system(size: 14, design: .monospaced))
                        Image(systemName: "calendar").font(.system(size: 11)).foregroundStyle(.secondary)
                    }
                }
                .buttonStyle(.plain)
                .popover(isPresented: $showDatePicker, arrowEdge: .bottom) {
                    DatePicker("Choose a date", selection: $selectedDate, displayedComponents: .date)
                        .datePickerStyle(.graphical).padding(12).frame(width: 280)
                }
                Button { shiftDate(1) } label: { Image(systemName: "chevron.right") }
                    .buttonStyle(.plain).foregroundStyle(ink.opacity(0.68))
                Spacer()
                Button("Today") { selectedDate = Date() }
                    .buttonStyle(.plain).font(.system(size: 11, design: .monospaced)).foregroundStyle(.secondary)
            }
            HStack(spacing: 6) {
                Text("TO-DO").font(.system(size: 12, weight: .semibold, design: .monospaced)).tracking(1.3)
                Spacer()
                Text("\(completedCount)/\(todaysTasks.count)")
                    .font(.system(size: 11, design: .monospaced)).foregroundStyle(.secondary)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.black.opacity(0.055))
                    Capsule().fill(Color(red: 0.83, green: 0.58, blue: 0.60))
                        .frame(width: todaysTasks.isEmpty ? 0 : geo.size.width * CGFloat(completedCount) / CGFloat(todaysTasks.count))
                }
            }
            .frame(height: 5)
        }
        .padding(.horizontal, 22).padding(.top, 31).padding(.bottom, 17)
    }

    private var taskList: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                ForEach(TaskCategory.allCases) { category in
                    let group = todaysTasks.filter { $0.category == category }
                    if !group.isEmpty {
                        VStack(alignment: .leading, spacing: 9) {
                            HStack(spacing: 8) {
                                Circle().fill(category.tint).frame(width: 8, height: 8)
                                Text(category.rawValue).font(.system(size: 12, design: .monospaced))
                                Text("\(group.filter(\.isDone).count)/\(group.count)")
                                    .font(.system(size: 10, design: .monospaced)).foregroundStyle(.secondary)
                                Spacer()
                            }
                            ForEach(group) { task in taskRow(task) }
                        }
                    }
                }
                if todaysTasks.isEmpty {
                    Text("No tasks for this day. Add one below.")
                        .font(.system(size: 12, design: .monospaced)).foregroundStyle(.tertiary)
                        .padding(.top, 9)
                }
            }
            .padding(.horizontal, 22).padding(.vertical, 18)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func taskRow(_ task: TodoItem) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Button { toggle(task) } label: {
                Image(systemName: task.isDone ? "checkmark.square.fill" : "square")
                    .font(.system(size: 17, weight: .regular))
                    .foregroundStyle(task.isDone ? Color(red: 0.63, green: 0.73, blue: 0.58) : Color.gray.opacity(0.58))
            }.buttonStyle(.plain)
            Text(task.title)
                .font(.system(size: 13, design: .monospaced))
                .strikethrough(task.isDone, color: completedTaskInk)
                .foregroundStyle(task.isDone ? completedTaskInk : ink)
                .frame(maxWidth: .infinity, alignment: .leading)
            Button { delete(task) } label: { Image(systemName: "xmark").font(.system(size: 10, weight: .medium)) }
                .buttonStyle(.plain).foregroundStyle(.tertiary)
        }
        .padding(.leading, 15)
        .contextMenu { Button("Delete", role: .destructive) { delete(task) } }
    }

    private var addBar: some View {
        VStack(spacing: 11) {
            Divider().overlay(Color.black.opacity(0.045))
            HStack(spacing: 8) {
                ZStack(alignment: .leading) {
                    if newTitle.isEmpty {
                        Text("Type a task…")
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(Color.gray.opacity(0.8))
                            .padding(.leading, 9)
                            .allowsHitTesting(false)
                    }
                    TextField("", text: $newTitle)
                        .textFieldStyle(.plain)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(ink)
                        .focused($inputFocused)
                        .onSubmit(addTask)
                        .padding(.horizontal, 9)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(minWidth: 130, maxWidth: .infinity, minHeight: 34, alignment: .leading)
                .background(Color.white, in: RoundedRectangle(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.black.opacity(0.14), lineWidth: 1))
                Picker("Category", selection: $newCategory) {
                    ForEach(TaskCategory.allCases) { category in Text(category.rawValue).tag(category) }
                }
                .labelsHidden().pickerStyle(.menu).fixedSize()
                Button(action: addTask) {
                    Image(systemName: "plus").font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white).frame(width: 29, height: 29)
                        .background(ink, in: RoundedRectangle(cornerRadius: 9))
                }.buttonStyle(.plain)
            }
            HStack {
                Text("DAILY · SAVED ON THIS MAC")
                Spacer()
                Text(Date.now.formatted(.dateTime.hour().minute()))
            }
            .font(.system(size: 9, design: .monospaced)).foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 20).padding(.top, 2).padding(.bottom, 13)
        .background(paper)
    }

    private func shiftDate(_ amount: Int) {
        if let next = Calendar.current.date(byAdding: .day, value: amount, to: selectedDate) { selectedDate = next }
    }
    private func addTask() {
        let title = newTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else {
            inputFocused = true
            return
        }
        tasks.append(TodoItem(title: title, category: newCategory, day: dayKey))
        newTitle = ""
        inputFocused = true
    }
    private func toggle(_ task: TodoItem) {
        guard let index = tasks.firstIndex(where: { $0.id == task.id }) else { return }
        tasks[index].isDone.toggle()
    }
    private func delete(_ task: TodoItem) { tasks.removeAll { $0.id == task.id } }
    private func seedIfNeeded() {
        guard !UserDefaults.standard.bool(forKey: "tinyTodoSeeded") else { return }
        let today = Self.key(for: Date())
        tasks = [
            TodoItem(title: "Finish the application", category: .work, day: today),
            TodoItem(title: "Review game theory", category: .school, day: today),
            TodoItem(title: "Asia quiz email", category: .school, day: today)
        ]
        UserDefaults.standard.set(true, forKey: "tinyTodoSeeded")
    }
    private func saveTasks() {
        guard let data = try? JSONEncoder().encode(tasks) else { return }
        UserDefaults.standard.set(data, forKey: "tinyTodoTasks")
    }
    private static func loadTasks() -> [TodoItem] {
        guard let data = UserDefaults.standard.data(forKey: "tinyTodoTasks"),
              let decoded = try? JSONDecoder().decode([TodoItem].self, from: data) else { return [] }
        return decoded
    }
    private static func key(for date: Date) -> String {
        let f = DateFormatter(); f.calendar = Calendar.current; f.locale = Locale(identifier: "en_US_POSIX"); f.timeZone = .current; f.dateFormat = "yyyy-MM-dd"
        return f.string(from: date)
    }
}
