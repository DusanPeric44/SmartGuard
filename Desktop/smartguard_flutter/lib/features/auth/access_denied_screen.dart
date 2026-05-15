import 'package:flutter/material.dart';
import 'package:smartguard_flutter/app/app_scope.dart';
import 'package:smartguard_flutter/core/auth/user_role.dart';

class AccessDeniedScreen extends StatelessWidget {
  const AccessDeniedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = AppScope.of(context).auth;
    final role = auth.role;
    final roleLabel = userRoleToWire(role);
    final isAdmin = role == UserRole.admin;

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pristup odbijen',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isAdmin
                        ? 'Ovaj ekran se ne bi trebao pojaviti za admin korisnika.'
                        : 'Ova desktop aplikacija je dostupna samo admin korisnicima.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Vaša uloga: $roleLabel',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      FilledButton.icon(
                        onPressed: () async {
                          await auth.logout();
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Odjavljeni ste.')),
                          );
                        },
                        icon: const Icon(Icons.logout),
                        label: const Text('Odjavi se'),
                      ),
                      FilledButton.tonalIcon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Kontaktirajte administratora za pristup.'),
                            ),
                          );
                        },
                        icon: const Icon(Icons.support_agent),
                        label: const Text('Kontakt'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

