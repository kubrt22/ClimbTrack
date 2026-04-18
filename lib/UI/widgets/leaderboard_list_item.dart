import 'package:flutter/material.dart';

class LeaderboardListTile extends StatelessWidget {
  final int rank;
  final String username;
  final String subtitle;
  final double points;
  final VoidCallback onTap;
  final bool isCurrentUser;

  const LeaderboardListTile({
    super.key,
    required this.rank,
    required this.username,
    required this.subtitle,
    required this.points,
    required this.onTap,
    this.isCurrentUser = false,
  });

  @override
  Widget build(BuildContext context) {
    final scoreColor = isCurrentUser
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.secondaryContainer;

    final scoreTextColor =
        ThemeData.estimateBrightnessForColor(scoreColor) == Brightness.dark
        ? Colors.white
        : Colors.black;

    return Material(
      color: Theme.of(context).colorScheme.surfaceContainer,
      borderRadius: BorderRadius.circular(8.0),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 84.0,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(color: const Color(0xFF49454F), width: 1.0),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 56,
                child: Center(
                  child: Text(
                    '$rank',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10.0,
                    vertical: 14.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        username,
                        style: Theme.of(context).textTheme.titleMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
              Ink(
                width: 92,
                height: double.infinity,
                decoration: BoxDecoration(color: scoreColor),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      points.toStringAsFixed(1),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: scoreTextColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'bodu',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: scoreTextColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
