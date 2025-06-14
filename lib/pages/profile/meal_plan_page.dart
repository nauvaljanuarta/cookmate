import 'package:cookmate2/models/day.dart';
import 'package:cookmate2/models/meal_plan.dart';
import 'package:cookmate2/services/meal_plan_service.dart';
import 'package:cookmate2/widgets/planned_meal_card.dart';
import 'package:flutter/cupertino.dart';

class MealPlanPage extends StatefulWidget {
  const MealPlanPage({super.key});

  @override
  State<MealPlanPage> createState() => _MealPlanPageState();
}

class _MealPlanPageState extends State<MealPlanPage> {
  final MealPlanService _mealPlanService = MealPlanService();

  List<Day> _days = [];
  Map<int, String> _daySegments = {};
  int _selectedSegment = 0;

  Future<List<MealPlan>>? _mealPlansFuture;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

 
  Future<void> _loadInitialData() async {
    final fetchedDays = await _mealPlanService.getDays();
    if (fetchedDays.isNotEmpty && mounted) {
      final initialDayId = fetchedDays.first.id;
      final initialPlansFuture = _mealPlanService.getMealPlansForDay(initialDayId);
      
      setState(() {
        _days = fetchedDays;
        _daySegments = {for (var i = 0; i < _days.length; i++) i: _days[i].name};
        _mealPlansFuture = initialPlansFuture;
      });
    }
  }

 
  void _onSegmentChanged(int? newValue) {
    if (newValue != null && mounted) {
      setState(() {
        _selectedSegment = newValue;
        final selectedDayId = _days[_selectedSegment].id;
        _mealPlansFuture = _mealPlanService.getMealPlansForDay(selectedDayId);
      });
    }
  }
  
  Future<void> _refreshPlans() async {
    if (_days.isNotEmpty && mounted) {
      final selectedDayId = _days[_selectedSegment].id;
      setState(() {
        _mealPlansFuture = _mealPlanService.getMealPlansForDay(selectedDayId);
      });
    }
  }

  Future<void> _handleDeletePlan(String mealPlanId) async {
    await _mealPlanService.deleteMealPlan(mealPlanId);
    if (mounted) {
      _refreshPlans();
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: CustomScrollView(
        slivers: [
          const CupertinoSliverNavigationBar(
            largeTitle: Text('Meal Planner'),
          ),
          CupertinoSliverRefreshControl(onRefresh: _refreshPlans),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: _daySegments.isEmpty
                  ? const Center(child: CupertinoActivityIndicator())
                  : CupertinoSegmentedControl<int>(
                      children: _daySegments.map(
                        (key, value) => MapEntry(
                          key,
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0),
                            child: Text(value),
                          ),
                        ),
                      ),
                      groupValue: _selectedSegment,
                      onValueChanged: _onSegmentChanged,
                    ),
            ),
          ),
          _buildMealPlanList(),
        ],
      ),
    );
  }

  Widget _buildMealPlanList() {
    if (_mealPlansFuture == null) {
      return const SliverFillRemaining(
        child: Center(child: CupertinoActivityIndicator()),
      );
    }
    return FutureBuilder<List<MealPlan>>(
      future: _mealPlansFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverFillRemaining(
              child: Center(child: CupertinoActivityIndicator()));
        }
        if (snapshot.hasError) {
          return SliverFillRemaining(child: Center(child: Text('Error: ${snapshot.error}')));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SliverFillRemaining(
            child: Center(
              child: Text('No meals planned for this day.'),
            ),
          );
        }
        final mealPlans = snapshot.data!;
        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final plan = mealPlans[index];
              return PlannedMealCard(
                mealPlan: plan,
                onDelete: () => _handleDeletePlan(plan.id),
              );
            },
            childCount: mealPlans.length,
          ),
        );
      },
    );
  }
}
