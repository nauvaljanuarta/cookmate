import 'package:cookmate2/config/theme.dart';
import 'package:cookmate2/models/day.dart';
import 'package:cookmate2/models/meal_plan.dart';
import 'package:cookmate2/services/meal_plan_service.dart';
import 'package:cookmate2/widgets/planned_meal_card.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class DayMealPlanRow extends StatefulWidget {
  final Day day;
  final Function(MealPlan, String) onCardDropped;
  final VoidCallback onPlanUpdated;

  const DayMealPlanRow({
    super.key,
    required this.day,
    required this.onCardDropped,
    required this.onPlanUpdated,
  });

  @override
  State<DayMealPlanRow> createState() => _DayMealPlanRowState();
}

class _DayMealPlanRowState extends State<DayMealPlanRow> {
  final MealPlanService _mealPlanService = MealPlanService();
  late Future<List<MealPlan>> _mealPlansFuture;

  @override
  void initState() {
    super.initState();
    _loadMealPlans();
  }

  void _loadMealPlans() {
    if (mounted) {
      setState(() {
        _mealPlansFuture = _mealPlanService.getMealPlansForDay(widget.day.id);
      });
    }
  }

  Future<void> _handleDeletePlan(String mealPlanId) async {
    await _mealPlanService.deleteMealPlan(mealPlanId);
    _loadMealPlans();
    widget.onPlanUpdated();
  }

  @override
  Widget build(BuildContext context) {
    return DragTarget<MealPlan>(
      builder: (context, candidateData, rejectedData) {
        final isTargeted = candidateData.isNotEmpty;
        return Container(
          color: isTargeted ? AppTheme.primaryColor.withOpacity(0.1) : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(widget.day.name, style: AppTheme.subheadingStyle),
              ),
              SizedBox(
                height: 110,
                child: FutureBuilder<List<MealPlan>>(
                  future: _mealPlansFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CupertinoActivityIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(
                        child: Text('Drag Here to Update your day yuhuu!!',
                            style:
                                TextStyle(color: CupertinoColors.systemGrey)),
                      );
                    }
                    final mealPlans = snapshot.data!;
                    return ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: mealPlans.length,
                      itemBuilder: (context, index) {
                        final plan = mealPlans[index];
                        return LongPressDraggable<MealPlan>(
                          data: plan,
                          feedback: Material(
                            color: Colors.transparent,
                            child: Opacity(
                              opacity: 0.8,
                              child: SizedBox(
                                width:
                                    MediaQuery.of(context).size.width * 0.75,
                                child: PlannedMealCard(
                                    mealPlan: plan, onDelete: () {}),
                              ),
                            ),
                          ),
                          childWhenDragging: Container(
                            width: MediaQuery.of(context).size.width * 0.75,
                            margin: const EdgeInsets.only(right: 12),
                            decoration: BoxDecoration(
                              color: CupertinoColors.systemGrey5,
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Container(
                            width: MediaQuery.of(context).size.width * 0.75,
                            margin: const EdgeInsets.only(right: 12),
                            child: PlannedMealCard(
                              mealPlan: plan,
                              onDelete: () => _handleDeletePlan(plan.id),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              const Divider(indent: 16, endIndent: 16),
            ],
          ),
        );
      },
      onAccept: (droppedPlan) {
        widget.onCardDropped(droppedPlan, widget.day.id);
      },
    );
  }
}