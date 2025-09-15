import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:get_it/get_it.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:hushh_user_app/features/pda/domain/entities/calendar_event.dart';
import 'package:hushh_user_app/features/pda/domain/usecases/calendar_use_cases.dart';

class GoogleMeetPage extends StatefulWidget {
  const GoogleMeetPage({super.key});

  @override
  State<GoogleMeetPage> createState() => _GoogleMeetPageState();
}

class _GoogleMeetPageState extends State<GoogleMeetPage>
    with TickerProviderStateMixin {
  final GetIt _getIt = GetIt.instance;
  late TabController _tabController;

  List<CalendarEvent> _allEvents = [];
  List<CalendarEvent> _todayEvents = [];
  List<CalendarEvent> _upcomingEvents = [];

  bool _isLoading = false;
  String? _error;
  bool _isRefreshing = false;

  // ChatGPT-style colors
  static const Color lightBackground = Color(0xFFFFFFFF);
  static const Color userBubbleColor = Color(0xFF000000);
  static const Color assistantBubbleColor = Color(0xFFF8F8F8);
  static const Color borderColor = Color(0xFFE0E0E0);
  static const Color textColor = Color(0xFF000000);
  static const Color hintColor = Color(0xFF666666);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadCalendarData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadCalendarData() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      setState(() {
        _error = 'User not authenticated';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final getCalendarEventsUseCase = _getIt<GetCalendarEventsUseCase>();
      final getTodayEventsUseCase = _getIt<GetTodayEventsUseCase>();
      final getUpcomingEventsUseCase = _getIt<GetUpcomingEventsUseCase>();

      // Load all data in parallel
      final results = await Future.wait([
        getCalendarEventsUseCase(currentUser.uid),
        getTodayEventsUseCase(currentUser.uid),
        getUpcomingEventsUseCase(currentUser.uid),
      ]);

      results[0].fold(
        (failure) => setState(() => _error = failure.toString()),
        (events) => setState(() => _allEvents = events),
      );

      results[1].fold(
        (failure) => setState(() => _error = failure.toString()),
        (events) => setState(() => _todayEvents = events),
      );

      results[2].fold(
        (failure) => setState(() => _error = failure.toString()),
        (events) => setState(() => _upcomingEvents = events),
      );

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Failed to load calendar data: $e';
      });
    }
  }

  Future<void> _openMeetingLink(String meetingLink) async {
    try {
      final Uri url = Uri.parse(meetingLink);
      if (await canLaunchUrl(url)) {
        await launchUrl(
          url,
          mode: LaunchMode.externalApplication, // This will open in Safari
        );
      } else {
        // Show error message if can't launch
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not open meeting link'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      // Show error message if launch fails
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening meeting: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _refreshData() async {
    setState(() {
      _isRefreshing = true;
    });

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        final refreshUseCase = _getIt<RefreshCalendarDataUseCase>();
        await refreshUseCase(currentUser.uid);
        await _loadCalendarData();
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to refresh data: $e';
      });
    } finally {
      setState(() {
        _isRefreshing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightBackground,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTodayTab(),
                _buildUpcomingTab(),
                _buildAllEventsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: lightBackground,
      elevation: 0,
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.arrow_back, color: textColor),
      ),
      title: const Text(
        'Google Meet',
        style: TextStyle(
          color: textColor,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      actions: const [],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: borderColor),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: lightBackground,
      child: TabBar(
        controller: _tabController,
        indicatorColor: userBubbleColor,
        labelColor: userBubbleColor,
        unselectedLabelColor: hintColor,
        labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        tabs: [
          Tab(text: 'Today (${_todayEvents.length})'),
          Tab(text: 'Upcoming (${_upcomingEvents.length})'),
          Tab(text: 'All Events (${_allEvents.length})'),
        ],
      ),
    );
  }

  Widget _buildTodayTab() {
    return _buildEventList(_todayEvents, 'No events scheduled for today');
  }

  Widget _buildUpcomingTab() {
    return _buildEventList(_upcomingEvents, 'No upcoming events');
  }

  Widget _buildAllEventsTab() {
    return _buildEventList(_allEvents, 'No calendar events found');
  }

  Widget _buildEventList(List<CalendarEvent> events, String emptyMessage) {
    if (_isLoading) {
      return _buildLoading();
    }

    if (_error != null) {
      return _buildErrorState();
    }

    if (events.isEmpty) {
      return _buildEmptyState(emptyMessage);
    }

    return RefreshIndicator(
      onRefresh: _refreshData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: events.length,
        itemBuilder: (context, index) {
          final event = events[index];
          return _buildEventCard(event);
        },
      ),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(textColor),
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Loading meetings...',
            style: TextStyle(color: hintColor, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard(CalendarEvent event) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: assistantBubbleColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: InkWell(
        onTap: () => _showEventDetails(event),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      event.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                  ),
                  if (event.meetingLink != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: userBubbleColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Meet',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.access_time, size: 16, color: hintColor),
                  const SizedBox(width: 6),
                  Text(
                    event.timeRange,
                    style: TextStyle(fontSize: 14, color: hintColor),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.schedule, size: 16, color: hintColor),
                  const SizedBox(width: 6),
                  Text(
                    event.formattedDuration,
                    style: TextStyle(fontSize: 14, color: hintColor),
                  ),
                ],
              ),
              if (event.location != null) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 16, color: hintColor),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        event.location!,
                        style: TextStyle(fontSize: 14, color: hintColor),
                      ),
                    ),
                  ],
                ),
              ],
              if (event.attendees.isNotEmpty) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.people, size: 16, color: hintColor),
                    const SizedBox(width: 6),
                    Text(
                      '${event.attendees.length} attendees',
                      style: TextStyle(fontSize: 14, color: hintColor),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_note, size: 64, color: hintColor),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(fontSize: 16, color: hintColor),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _refreshData,
            style: ElevatedButton.styleFrom(
              backgroundColor: userBubbleColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Refresh'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
          const SizedBox(height: 16),
          Text(
            _error!,
            style: TextStyle(fontSize: 16, color: Colors.red[400]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadCalendarData,
            style: ElevatedButton.styleFrom(
              backgroundColor: userBubbleColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  void _showEventDetails(CalendarEvent event) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(event.title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (event.description != null) ...[
                const Text(
                  'Description:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(event.description!),
                const SizedBox(height: 12),
              ],
              const Text(
                'Time:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(event.timeRange),
              const SizedBox(height: 12),
              const Text(
                'Duration:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(event.formattedDuration),
              if (event.location != null) ...[
                const SizedBox(height: 12),
                const Text(
                  'Location:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(event.location!),
              ],
              if (event.attendees.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text(
                  'Attendees:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                ...event.attendees.map((attendee) => Text('• $attendee')),
              ],
              if (event.meetingLink != null) ...[
                const SizedBox(height: 12),
                const Text(
                  'Meeting Link:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(event.meetingLink!),
              ],
            ],
          ),
        ),
        actions: [
          if (event.meetingLink != null)
            CupertinoDialogAction(
              onPressed: () {
                Navigator.pop(context);
                _openMeetingLink(event.meetingLink!);
              },
              child: const Text('Join Meeting'),
            ),
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
