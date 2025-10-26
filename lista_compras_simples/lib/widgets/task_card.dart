import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';
import '../models/category.dart';

class TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback onTap;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const TaskCard({
    super.key,
    required this.task,
    required this.onTap,
    required this.onToggle,
    required this.onDelete,
  });

  Color _getPriorityColor() {
    switch (task.priority) {
      case 'low':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'high':
        return Colors.red;
      case 'urgent':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getPriorityIcon() {
    switch (task.priority) {
      case 'urgent':
        return Icons.priority_high;
      default:
        return Icons.flag;
    }
  }

  String _getPriorityLabel() {
    switch (task.priority) {
      case 'low':
        return 'Baixa';
      case 'medium':
        return 'Média';
      case 'high':
        return 'Alta';
      case 'urgent':
        return 'Urgente';
      default:
        return 'Média';
    }
  }

  Color _getCategoryColor(String colorHex) {
    return Color(int.parse('0x$colorHex'));
  }

  IconData _getCategoryIcon(String iconName) {
    switch (iconName) {
      case 'work': return Icons.work;
      case 'person': return Icons.person;
      case 'school': return Icons.school;
      case 'favorite': return Icons.favorite;
      case 'shopping_cart': return Icons.shopping_cart;
      case 'home': return Icons.home;
      case 'category': return Icons.category;
      default: return Icons.category;
    }
  }

  Widget _buildCategoryBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getCategoryColor(task.category.color).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getCategoryColor(task.category.color),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getCategoryIcon(task.category.icon),
            size: 12,
            color: _getCategoryColor(task.category.color),
          ),
          const SizedBox(width: 4),
          Text(
            task.category.name,
            style: TextStyle(
              fontSize: 10,
              color: _getCategoryColor(task.category.color),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDueDateInfo() {
    if (task.dueDate == null) return const SizedBox.shrink();
    
    final now = DateTime.now();
    final dueDate = task.dueDate!;
    final isOverdue = task.isOverdue;
    final isDueToday = task.isDueToday;
    
    Color dateColor;
    IconData dateIcon;
    String dateText;
    
    if (isOverdue) {
      dateColor = Colors.red;
      dateIcon = Icons.warning;
      dateText = 'Vencida: ${DateFormat('dd/MM/yyyy').format(dueDate)}';
    } else if (isDueToday) {
      dateColor = Colors.orange;
      dateIcon = Icons.today;
      dateText = 'Vence hoje!';
    } else {
      dateColor = Colors.blue;
      dateIcon = Icons.event;
      dateText = 'Vence: ${DateFormat('dd/MM/yyyy').format(dueDate)}';
    }
    
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: dateColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: dateColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(dateIcon, size: 14, color: dateColor),
          const SizedBox(width: 4),
          Text(
            dateText,
            style: TextStyle(
              fontSize: 12,
              color: dateColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: task.completed ? 1 : 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: task.completed ? Colors.grey.shade300 : _getCategoryColor(task.category.color),
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Checkbox
              Checkbox(
                value: task.completed,
                onChanged: (_) => onToggle(),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Conteúdo Principal
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Título
                    Text(
                      task.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        decoration: task.completed 
                            ? TextDecoration.lineThrough 
                            : null,
                        color: task.completed 
                            ? Colors.grey 
                            : Colors.black,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    if (task.description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        task.description,
                        style: TextStyle(
                          fontSize: 14,
                          color: task.completed 
                              ? Colors.grey.shade400 
                              : Colors.grey.shade700,
                          decoration: task.completed 
                              ? TextDecoration.lineThrough 
                              : null,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    
                    const SizedBox(height: 8),
                    
                    // Metadata Row
                    Row(
                      children: [
                        _buildCategoryBadge(),
                        const SizedBox(width: 8),
                        // Prioridade
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _getPriorityColor(),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _getPriorityIcon(),
                                size: 12,
                                color: _getPriorityColor(),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _getPriorityLabel(),
                                style: TextStyle(
                                  fontSize: 10,
                                  color: _getPriorityColor(),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(width: 8),
                        
                        // Data
                        Icon(
                          Icons.access_time,
                          size: 12,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('dd/MM/yy').format(task.createdAt),
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    
                    _buildDueDateInfo(),
                  ],
                ),
              ),
              
              const SizedBox(width: 8),
              
              // Botão Deletar
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline),
                color: Colors.red,
                tooltip: 'Deletar tarefa',
              ),
            ],
          ),
        ),
      ),
    );
  }
}