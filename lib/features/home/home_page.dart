import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("WakeQuest")),

      floatingActionButton: FloatingActionButton(
        onPressed: () {},

        child: const Icon(Icons.add),
      ),

      body: ListView(
        padding: const EdgeInsets.all(20),

        children: [
          const Text(
            "Good Morning 👋",
            style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 30),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  const Text("Next Alarm", style: TextStyle(fontSize: 16)),

                  const SizedBox(height: 10),

                  const Text(
                    "07:00 AM",
                    style: TextStyle(fontSize: 42, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 10),

                  FilledButton(
                    onPressed: () {},

                    child: const Text("Start Test Alarm"),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
