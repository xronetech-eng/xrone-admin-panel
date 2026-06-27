import 'package:flutter/material.dart';

import '_pilot_ui.dart';

class AdminConfigurationSection extends StatelessWidget {
  const AdminConfigurationSection({super.key});

  @override
  Widget build(BuildContext context) {
    return const PilotSectionCard(
      title: 'Home Dashboard Settings',
      subtitle: 'No Supabase-backed settings source is defined in Pilots.',
      child: PilotEmptyState(
        message:
            'Admin settings such as max ongoing bookings, journey buffer time, '
            'currency, minimum wallet amount, cancellation window, help and '
            'privacy policy are not rendered with static values.',
      ),
    );
  }
}
