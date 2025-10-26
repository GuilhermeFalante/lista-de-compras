import 'package:flutter/material.dart';
import '../models/task.dart';
import '../models/category.dart';
import '../services/database_service.dart';
import '../widgets/task_card.dart';
import 'task_form_screen.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  List<Task> _tasks = [];
  String _filter = 'all'; 
  String _sortBy = 'date'; 
  String _categoryFilter = 'all'; 
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    setState(() => _isLoading = true);
    List<Task> tasks;
    
    if (_sortBy == 'dueDate') {
      tasks = await DatabaseService.instance.readAllByDueDate();
    } else if (_categoryFilter != 'all' && _categoryFilter != '') {
      tasks = await DatabaseService.instance.readByCategory(_categoryFilter);
    } else {
      tasks = await DatabaseService.instance.readAll();
    }
    
    setState(() {
      _tasks = tasks;
      _isLoading = false;
    });
  }

  List<Task> get _filteredTasks {
    var tasks = _tasks;
    
    switch (_filter) {
      case 'completed':
        tasks = tasks.where((t) => t.completed).toList();
        break;
      case 'pending':
        tasks = tasks.where((t) => !t.completed).toList();
        break;
    }
    
    if (_categoryFilter != 'all' && _sortBy != 'dueDate') {
      tasks = tasks.where((t) => t.category.id == _categoryFilter).toList();
    }
    
    if (_sortBy != 'dueDate') {
      switch (_sortBy) {
        case 'priority':
          final priorityOrder = {'urgent': 0, 'high': 1, 'medium': 2, 'low': 3};
          tasks.sort((a, b) {
            final orderA = priorityOrder[a.priority] ?? 2;
            final orderB = priorityOrder[b.priority] ?? 2;
            return orderA.compareTo(orderB);
          });
          break;
        case 'category':
          tasks.sort((a, b) => a.category.name.compareTo(b.category.name));
          break;
        case 'date':
        default:
          tasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      }
    }
    
    return tasks;
  }
  Future<void> _toggleTask(Task task) async {
    final updated = task.copyWith(completed: !task.completed);
    await DatabaseService.instance.update(updated);
    await _loadTasks();
  }

  Future<void> _deleteTask(Task task) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar exclusão'),
        content: Text('Deseja realmente excluir "${task.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await DatabaseService.instance.delete(task.id);
      await _loadTasks();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tarefa excluída'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _openTaskForm([Task? task]) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TaskFormScreen(task: task),
      ),
    );

    if (result == true) {
      await _loadTasks();
    }
  }

  Color _getCategoryColor(String colorHex) {
    return Color(int.parse('0x$colorHex'));
  }

  Widget _buildCategoryChips() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              selected: _categoryFilter == 'all',
              label: const Text('Todas'),
              onSelected: (selected) {
                setState(() => _categoryFilter = 'all');
                _loadTasks();
              },
              backgroundColor: Colors.grey.shade200,
              selectedColor: Colors.blue,
              labelStyle: TextStyle(
                color: _categoryFilter == 'all' ? Colors.white : Colors.black,
              ),
            ),
          ),
          ...DefaultCategories.categories.map((category) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                selected: _categoryFilter == category.id,
                label: Text(category.name),
                avatar: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: _getCategoryColor(category.color),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.circle,
                    color: _getCategoryColor(category.color),
                    size: 16,
                  ),
                ),
                onSelected: (selected) {
                  setState(() => _categoryFilter = category.id);
                  _loadTasks();
                },
                backgroundColor: Colors.grey.shade200,
                selectedColor: _getCategoryColor(category.color).withOpacity(0.3),
                labelStyle: TextStyle(
                  color: _categoryFilter == category.id 
                      ? _getCategoryColor(category.color) 
                      : Colors.black,
                  fontWeight: _categoryFilter == category.id 
                      ? FontWeight.bold 
                      : FontWeight.normal,
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredTasks = _filteredTasks;
    final stats = _calculateStats();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Minhas Tarefas'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            onSelected: (value) {
              setState(() => _sortBy = value);
              _loadTasks();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'date',
                child: Row(
                  children: [
                    Icon(Icons.access_time),
                    SizedBox(width: 8),
                    Text('Data de Criação'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'dueDate',
                child: Row(
                  children: [
                    Icon(Icons.event),
                    SizedBox(width: 8),
                    Text('Data de Vencimento'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'priority',
                child: Row(
                  children: [
                    Icon(Icons.flag),
                    SizedBox(width: 8),
                    Text('Prioridade'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'category',
                child: Row(
                  children: [
                    Icon(Icons.category),
                    SizedBox(width: 8),
                    Text('Categoria'),
                  ],
                ),
              ),
            ],
          ),
          // Filtro de Status
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) => setState(() => _filter = value),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'all',
                child: Row(
                  children: [
                    Icon(Icons.list),
                    SizedBox(width: 8),
                    Text('Todas'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'pending',
                child: Row(
                  children: [
                    Icon(Icons.pending_actions),
                    SizedBox(width: 8),
                    Text('Pendentes'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'completed',
                child: Row(
                  children: [
                    Icon(Icons.check_circle),
                    SizedBox(width: 8),
                    Text('Concluídas'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      
      body: Column(
        children: [
          _buildCategoryChips(),
          if (_tasks.isNotEmpty)
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.blue, Colors.blueAccent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem(Icons.list, 'Total', stats['total'].toString()),
                      _buildStatItem(Icons.pending_actions, 'Pendentes', stats['pending'].toString()),
                      _buildStatItem(Icons.check_circle, 'Concluídas', stats['completed'].toString()),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (stats['overdue']! > 0 || stats['dueToday']! > 0)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        if (stats['overdue']! > 0)
                          _buildStatItem(Icons.warning, 'Vencidas', stats['overdue'].toString(), color: Colors.red.shade100),
                        if (stats['dueToday']! > 0)
                          _buildStatItem(Icons.today, 'Hoje', stats['dueToday'].toString(), color: Colors.orange.shade100),
                      ],
                    ),
                ],
              ),
            ),
          
          // Lista de Tarefas
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredTasks.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadTasks,
                        child: ListView.builder(
                          padding: const EdgeInsets.only(bottom: 80),
                          itemCount: filteredTasks.length,
                          itemBuilder: (context, index) {
                            final task = filteredTasks[index];
                            return TaskCard(
                              task: task,
                              onTap: () => _openTaskForm(task),
                              onToggle: () => _toggleTask(task),
                              onDelete: () => _deleteTask(task),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openTaskForm(),
        icon: const Icon(Icons.add),
        label: const Text('Nova Tarefa'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label, String value, {Color? color}) {
    final iconColor = color ?? Colors.white;
    final textColor = color ?? Colors.white;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: iconColor, size: 28),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: textColor,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: textColor.withOpacity(0.9),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    String message;
    IconData icon;
    
    if (_categoryFilter != 'all') {
      final category = DefaultCategories.categories.firstWhere(
        (c) => c.id == _categoryFilter,
        orElse: () => DefaultCategories.defaultCategory,
      );
      message = 'Nenhuma tarefa na categoria ${category.name}';
      icon = Icons.category;
    } else {
      switch (_filter) {
        case 'completed':
          message = 'Nenhuma tarefa concluída ainda';
          icon = Icons.check_circle_outline;
          break;
        case 'pending':
          message = 'Nenhuma tarefa pendente';
          icon = Icons.pending_actions;
          break;
        default:
          message = 'Nenhuma tarefa cadastrada';
          icon = Icons.task_alt;
      }
    }
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 100, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () => _openTaskForm(),
            icon: const Icon(Icons.add),
            label: const Text('Criar primeira tarefa'),
          ),
        ],
      ),
    );
  }

  Map<String, int> _calculateStats() {
    final now = DateTime.now();
    final filteredTasks = _categoryFilter == 'all' 
        ? _tasks 
        : _tasks.where((t) => t.category.id == _categoryFilter).toList();
    
    final overdueCount = filteredTasks.where((t) => t.isOverdue).length;
    final dueTodayCount = filteredTasks.where((t) => t.isDueToday && !t.completed).length;
    
    return {
      'total': filteredTasks.length,
      'completed': filteredTasks.where((t) => t.completed).length,
      'pending': filteredTasks.where((t) => !t.completed).length,
      'overdue': overdueCount,
      'dueToday': dueTodayCount,
    };
  }
}