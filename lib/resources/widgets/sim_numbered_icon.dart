import 'package:flutter/material.dart';

class SimCardIcon extends StatelessWidget {
  final int simNumber;
  final bool isSelected;

  const SimCardIcon({
    super.key,
    required this.simNumber,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Icon(
          Icons.sim_card,
          size: 40,
          color: isSelected ? Colors.blue : Colors.grey[600],
        ),
        Positioned(
          top: 10,
          child: Text(
            simNumber.toString(),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : Colors.black,
            ),
          ),
        ),
      ],
    );
  }
}
