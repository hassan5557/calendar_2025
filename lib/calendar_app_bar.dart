import 'package:flutter/material.dart';
import 'package:flutter_calendar99/event/event.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

class CalendarAppBar extends StatefulWidget implements PreferredSizeWidget {
  final CalendarView currentView;
  final ValueNotifier<List<Event>> eventsNotifier;
  final Function(String) onSearch;
  final void Function(String value) onViewSelected;
  
  const CalendarAppBar({
    super.key,
    required this.currentView,
    required this.eventsNotifier,
    required this.onSearch,
    required this.onViewSelected,
  });

  @override
  State<CalendarAppBar> createState() => _CalendarAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 10);
}

class _CalendarAppBarState extends State<CalendarAppBar> with SingleTickerProviderStateMixin {
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    _searchController.addListener(() => widget.onSearch(_searchController.text));
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (_isSearching) {
        _animationController.forward();
        _searchFocusNode.requestFocus();
      } else {
        _animationController.reverse();
        _searchController.clear();
        widget.onSearch('');
        _searchFocusNode.unfocus();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _isSearching
            ? FadeTransition(
                opacity: _fadeAnimation,
                child: TextField(
                  key: const ValueKey('search-field'),
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  autofocus: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search events...',
                    hintStyle: const TextStyle(color: Colors.white70),
                    border: InputBorder.none,
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 20),
                            onPressed: () {
                              _searchController.clear();
                              widget.onSearch('');
                            },
                          )
                        : null,
                  ),
                ),
              )
            : const Row(
                key: ValueKey('title'),
                children: [
                  Icon(Icons.calendar_month_rounded, size: 24),
                  SizedBox(width: 12),
                  Text(
                    'Calendar',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
      ),
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
      elevation: 0,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFF2A2A2A),
              Color(0xFF1B191A),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(24),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
      ),
      actions: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: _isSearching
              ? IconButton(
                  key: const ValueKey('close-search'),
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                  onPressed: _toggleSearch,
                )
              : IconButton(
                  key: const ValueKey('open-search'),
                  icon: const Icon(Icons.search_rounded, color: Colors.white),
                  onPressed: _toggleSearch,
                ),
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
          tooltip: 'Calendar Views',
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          position: PopupMenuPosition.under,
          onSelected: widget.onViewSelected,
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'month',
              child: ListTile(
                leading: Icon(Icons.calendar_view_month),
                title: Text('Month View'),
              ),
            ),
            const PopupMenuItem(
              value: 'all_tasks',
              child: ListTile(
                leading: Icon(Icons.list),
                title: Text('All Tasks'),
              ),
            ),
            const PopupMenuItem(
              value: 'done',
              child: ListTile(
                leading: Icon(Icons.check_circle, color: Colors.green),
                title: Text('Done Tasks'),
              ),
            ),
            const PopupMenuItem(
              value: 'delayed',
              child: ListTile(
                leading: Icon(Icons.schedule, color: Colors.orange),
                title: Text('Delayed Tasks'),
              ),
            ),
          ],
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}