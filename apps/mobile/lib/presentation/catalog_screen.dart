import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/demo_devices.dart';

final class CatalogScreen extends StatelessWidget {
  const CatalogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vodič za uređaje')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: demoDevices.length + 1,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          if (index == 0) {
            return Card(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Pronađite odgovarajući uređaj', style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 8),
                    const Text(
                      'Početni KT1 katalog koristi lažne podatke. Upitnik i poređenje dolaze u sledećim iteracijama.',
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: () => context.go('/reviews'),
                      icon: const Icon(Icons.reviews_outlined),
                      label: const Text('Pogledaj recenzije'),
                    ),
                  ],
                ),
              ),
            );
          }
          final device = demoDevices[index - 1];
          return Card(
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.air)),
              title: Text(device.name),
              subtitle: Text('${device.category}\n${device.description}'),
              isThreeLine: true,
            ),
          );
        },
      ),
    );
  }
}
