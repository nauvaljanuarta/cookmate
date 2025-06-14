import 'package:cookmate2/models/day.dart';
import 'package:cookmate2/models/meal_plan.dart';
import 'package:cookmate2/services/meal_plan_service.dart';
import 'package:cookmate2/widgets/day_meal_plan_row.dart';
import 'package:flutter/cupertino.dart';

class MealPlanPage extends StatefulWidget {
  const MealPlanPage({super.key});

  @override
  State<MealPlanPage> createState() => _MealPlanPageState();
}

class _MealPlanPageState extends State<MealPlanPage> {
  final MealPlanService _mealPlanService = MealPlanService();
  late Future<List<Day>> _daysFuture;

  @override
  void initState() {
    super.initState();
    _daysFuture = _mealPlanService.getDays();
  }

  Future<void> _refreshPage() async {
    setState(() {
      _daysFuture = _mealPlanService.getDays();
    });
  }

  Future<void> _handleCardDrop(MealPlan plan, String newDayId) async {
    if (plan.dayId == newDayId) {
      return;
    }
    
    try {
      await _mealPlanService.updateMealPlanDay(plan.id, newDayId);
      _refreshPage();
    } catch (e) {
      print("Failed to move plan: $e");
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
          CupertinoSliverRefreshControl(onRefresh: _refreshPage),
          SliverToBoxAdapter(
            child: FutureBuilder<List<Day>>(
              future: _daysFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    heightFactor: 10,
                    child: CupertinoActivityIndicator(),
                  );
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('Days Not Fund.'));
                }
                final days = snapshot.data!;
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: days.length,
                  itemBuilder: (context, index) {
                    final day = days[index];
                    return DayMealPlanRow(
                      key: ValueKey(day.id),
                      day: day,
                      onCardDropped: _handleCardDrop, 
                      onPlanUpdated: _refreshPage,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}