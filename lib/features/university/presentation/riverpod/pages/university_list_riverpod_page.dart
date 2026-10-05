import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_clean_architecture/core/config/constants.dart';
import 'package:flutter_clean_architecture/features/university/presentation/riverpod/providers/university_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// --------------------------------------------------------------
/// Page (Riverpod version of [UniversityListPage])
/// --------------------------------------------------------------
class UniversityListRiverpodPage extends ConsumerStatefulWidget {
  const UniversityListRiverpodPage({super.key});

  @override
  ConsumerState<UniversityListRiverpodPage> createState() =>
      _UniversityListRiverpodPageState();
}

class _UniversityListRiverpodPageState
    extends ConsumerState<UniversityListRiverpodPage> {
  @override
  void initState() {
    super.initState();
    // Dispatch initial load ONCE when the screen loads.
    Future.microtask(
      () => ref.read(universityListProvider.notifier).loadData(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isActiveSearch = ref.watch(
      universityListProvider.select((state) => state.isActiveSearch),
    );

    return Scaffold(
      appBar: AppBar(
        title:
            isActiveSearch
                ? const RiverpodSearchField()
                : const Text("Flutter Clean Architecture (Riverpod)"),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        actions: const [RiverpodSearchIcon()],
      ),
      body: const UniversityListRiverpodScreen(),
    );
  }
}

/// --------------------------------------------------------------
/// Screen
/// --------------------------------------------------------------
class UniversityListRiverpodScreen extends ConsumerWidget {
  const UniversityListRiverpodScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(universityListProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        final notifier = ref.read(universityListProvider.notifier);
        state.isActiveSearch
            ? notifier.resetData()
            : showDialog<String>(
              context: context,
              builder:
                  (BuildContext context) => AlertDialog(
                    title: const Text('Confirmation'),
                    content: const Text('Are you sure you want to exit?'),
                    actions: <Widget>[
                      TextButton(
                        onPressed: () => Navigator.pop(context, 'Cancel'),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () async {
                          Navigator.pop(context, 'OK');
                          SystemNavigator.pop();
                        },
                        child: const Text('OK'),
                      ),
                    ],
                  ),
            );
      },
      child: Stack(
        children: [
          Builder(
            builder: (context) {
              if (state.status == Status.loaded ||
                  state.universities.isNotEmpty) {
                return Column(
                  children: [
                    SizedBox(
                      height: 60,
                      child: ListView.builder(
                        itemCount: state.countries.length,
                        itemBuilder: (context, index) {
                          return GestureDetector(
                            onTap: () {
                              ref
                                  .read(universityListProvider.notifier)
                                  .search(
                                    keyword: "",
                                    country: state.countries[index].name,
                                  );
                            },
                            child: MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: Container(
                                margin: const EdgeInsets.only(
                                  left: 10,
                                  right: 10,
                                  bottom: 15,
                                  top: 15,
                                ),
                                padding: const EdgeInsets.only(
                                  left: 20,
                                  right: 20,
                                  top: 4,
                                  bottom: 4,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      (state.params.country ==
                                                  state
                                                      .countries[index]
                                                      .name) ||
                                              (state.params.country == "" &&
                                                  state.countries[index].name ==
                                                      "All")
                                          ? const Color.fromARGB(
                                            189,
                                            121,
                                            15,
                                            167,
                                          )
                                          : const Color.fromARGB(
                                            190,
                                            63,
                                            5,
                                            88,
                                          ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  state.countries[index].name,
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                          );
                        },
                        scrollDirection: Axis.horizontal,
                      ),
                    ),
                    Expanded(
                      child: NotificationListener<ScrollNotification>(
                        onNotification: (notification) {
                          if (notification is ScrollEndNotification) {
                            final metrics = notification.metrics;
                            if (metrics.atEdge && metrics.pixels != 0) {
                              // Hit the end of the list
                              ref
                                  .read(universityListProvider.notifier)
                                  .loadMore();
                            }
                          }
                          return false;
                        },
                        child: RefreshIndicator(
                          child: ListView.builder(
                            itemCount: state.universities.length,
                            itemBuilder: (context, index) {
                              return ListTile(
                                title: Text(
                                  '${state.universities[index].name} ( ${state.universities[index].country} ) ',
                                ),
                              );
                            },
                          ),
                          onRefresh: () {
                            ref
                                .read(universityListProvider.notifier)
                                .loadData();
                            return Future.delayed(const Duration(seconds: 1));
                          },
                        ),
                      ),
                    ),
                  ],
                );
              } else if (state.status == Status.error) {
                return Center(
                  child: Text(
                    state.errorMessage,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                );
              } else {
                return const SizedBox();
              }
            },
          ),
          Builder(
            builder: (context) {
              final status = ref.watch(
                universityListProvider.select((state) => state.status),
              );
              if (status == Status.loading) {
                return const Align(
                  alignment: Alignment.bottomCenter,
                  child: LinearProgressIndicator(),
                );
              } else {
                return const SizedBox();
              }
            },
          ),
        ],
      ),
    );
  }
}

/// Search/close action button, mirroring [AppBarSearchIconWidget].
class RiverpodSearchIcon extends ConsumerWidget {
  const RiverpodSearchIcon({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isActiveSearch = ref.watch(
      universityListProvider.select((state) => state.isActiveSearch),
    );
    final notifier = ref.read(universityListProvider.notifier);

    return !isActiveSearch
        ? IconButton(
          onPressed: () => notifier.setSearchActive(true),
          icon: const Icon(Icons.search),
        )
        : IconButton(
          onPressed: () => notifier.resetData(),
          icon: const Icon(Icons.close),
        );
  }
}

/// Search input shown in the app bar, mirroring [AppBarTitleWidget].
class RiverpodSearchField extends ConsumerStatefulWidget {
  const RiverpodSearchField({super.key});

  @override
  ConsumerState<RiverpodSearchField> createState() =>
      _RiverpodSearchFieldState();
}

class _RiverpodSearchFieldState extends ConsumerState<RiverpodSearchField> {
  final TextEditingController controller = TextEditingController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      autofocus: true,
      controller: controller,
      decoration: InputDecoration(
        hintText: 'Enter Search Keyword',
        hintStyle: TextStyle(color: Theme.of(context).highlightColor),
      ),
      textInputAction: TextInputAction.search,
      style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
      onChanged: (value) {
        ref
            .read(universityListProvider.notifier)
            .search(keyword: controller.text, country: "");
      },
    );
  }
}
