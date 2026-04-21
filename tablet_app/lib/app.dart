import 'package:flutter/material.dart';

import 'core/api_client.dart';

const _apiBaseUrl = String.fromEnvironment(
  'GOLF_EDGE_API_BASE_URL',
  defaultValue: 'http://127.0.0.1:8000',
);

class GolfEdgeApp extends StatelessWidget {
  const GolfEdgeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Golf Edge',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
      ),
      home: const RoundWorkspacePage(),
    );
  }
}

class RoundWorkspacePage extends StatefulWidget {
  const RoundWorkspacePage({super.key});

  @override
  State<RoundWorkspacePage> createState() => _RoundWorkspacePageState();
}

class _RoundWorkspacePageState extends State<RoundWorkspacePage> {
  final ApiClient _apiClient = ApiClient(baseUrl: _apiBaseUrl);

  final TextEditingController _controlClubController = TextEditingController();
  final TextEditingController _controlDistanceController = TextEditingController();
  final TextEditingController _controlBallTypeController = TextEditingController(
    text: 'RCT',
  );
  final TextEditingController _controlTeeUsedController = TextEditingController(
    text: 'Blue',
  );
  final TextEditingController _controlTeeHeightController = TextEditingController(
    text: '1.75 in',
  );
  final TextEditingController _controlSwingTypeController = TextEditingController(
    text: 'full swing',
  );

  final TextEditingController _shotClubController = TextEditingController();
  final TextEditingController _shotLieController = TextEditingController(
    text: 'fairway',
  );
  final TextEditingController _shotPenaltiesController = TextEditingController(
    text: '0',
  );
  final TextEditingController _shotPuttsController = TextEditingController(
    text: '0',
  );
  final TextEditingController _shotNotesController = TextEditingController();
  final TextEditingController _shotTeeUsedController = TextEditingController();
  final TextEditingController _shotTeeHeightController = TextEditingController();
  final TextEditingController _shotBallTypeController = TextEditingController();
  final TextEditingController _shotSwingTypeController = TextEditingController();
  final TextEditingController _shotTargetDistanceController = TextEditingController();

  bool _isLoading = true;
  String? _error;
  String? _roundId;
  Map<String, dynamic>? _workspace;
  List<Map<String, dynamic>> _courses = const [];

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _controlClubController.dispose();
    _controlDistanceController.dispose();
    _controlBallTypeController.dispose();
    _controlTeeUsedController.dispose();
    _controlTeeHeightController.dispose();
    _controlSwingTypeController.dispose();
    _shotClubController.dispose();
    _shotLieController.dispose();
    _shotPenaltiesController.dispose();
    _shotPuttsController.dispose();
    _shotNotesController.dispose();
    _shotTeeUsedController.dispose();
    _shotTeeHeightController.dispose();
    _shotBallTypeController.dispose();
    _shotSwingTypeController.dispose();
    _shotTargetDistanceController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _holeStates =>
      List<Map<String, dynamic>>.from(_workspace?['hole_states'] as List? ?? const []);

  List<Map<String, dynamic>> get _recentShots =>
      List<Map<String, dynamic>>.from(_workspace?['recent_shots'] as List? ?? const []);

  Map<String, dynamic>? get _controls =>
      _workspace?['controls'] is Map<String, dynamic>
          ? _workspace?['controls'] as Map<String, dynamic>
          : null;

  Map<String, dynamic>? get _guidance =>
      _workspace?['guidance'] is Map<String, dynamic>
          ? _workspace?['guidance'] as Map<String, dynamic>
          : null;

  int get _currentHoleNumber => (_workspace?['current_hole_number'] as int?) ?? 1;

  Future<void> _bootstrap() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final coursesResponse = await _apiClient.getJson('/courses');
      final items = List<Map<String, dynamic>>.from(
        coursesResponse['items'] as List? ?? const [],
      );
      if (items.isEmpty) {
        throw const ApiClientException('No courses were returned by the API.');
      }

      final roundResponse = await _apiClient.postJson(
        '/rounds/start',
        body: {'course_id': items.first['id']},
      );

      _courses = items;
      _roundId = roundResponse['round_id'] as String?;
      await _refreshWorkspace();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshWorkspace() async {
    if (_roundId == null) return;

    final workspace = await _apiClient.getJson('/rounds/$_roundId/workspace');
    if (!mounted) return;

    setState(() {
      _workspace = workspace;
      _isLoading = false;
      _error = null;
    });
    _syncControllersWithWorkspace();
  }

  void _syncControllersWithWorkspace() {
    final controls = _controls;
    if (controls != null) {
      _controlClubController.text = _stringOrEmpty(controls['selected_club']);
      _controlDistanceController.text = _stringOrEmpty(
        controls['radar_to_ball_distance'],
      );
      _controlBallTypeController.text = _stringOrEmpty(
        controls['ball_type'],
        fallback: 'RCT',
      );
      _controlTeeUsedController.text = _stringOrEmpty(
        controls['tee_used'],
        fallback: 'Blue',
      );
      _controlTeeHeightController.text = _stringOrEmpty(
        controls['tee_height'],
        fallback: '1.75 in',
      );
      _controlSwingTypeController.text = _stringOrEmpty(
        controls['swing_type'],
        fallback: 'full swing',
      );
    }

    _shotClubController.text = _controlClubController.text;
    _shotTeeUsedController.text = _controlTeeUsedController.text;
    _shotTeeHeightController.text = _controlTeeHeightController.text;
    _shotBallTypeController.text = _controlBallTypeController.text;
    _shotSwingTypeController.text = _controlSwingTypeController.text;
    _shotTargetDistanceController.text = _controlDistanceController.text;
  }

  Future<void> _saveControls() async {
    if (_roundId == null) return;

    await _apiClient.postJson(
      '/rounds/$_roundId/controls',
      body: {
        'selected_club': _nullIfBlank(_controlClubController.text),
        'radar_to_ball_distance': _doubleOrNull(_controlDistanceController.text),
        'ball_type': _nullIfBlank(_controlBallTypeController.text),
        'tee_used': _nullIfBlank(_controlTeeUsedController.text),
        'tee_height': _nullIfBlank(_controlTeeHeightController.text),
        'swing_type': _nullIfBlank(_controlSwingTypeController.text),
      },
    );
    await _refreshWorkspace();
    _showMessage('Control panel updated.');
  }

  Future<void> _saveShot() async {
    if (_roundId == null) return;

    await _apiClient.postJson(
      '/rounds/$_roundId/shots',
      body: {
        'hole_number': _currentHoleNumber,
        'club_used': _nullIfBlank(_shotClubController.text),
        'lie': _nullIfBlank(_shotLieController.text),
        'penalties': _intOrZero(_shotPenaltiesController.text),
        'putts': _intOrZero(_shotPuttsController.text),
        'notes': _nullIfBlank(_shotNotesController.text),
        'tee_used': _nullIfBlank(_shotTeeUsedController.text),
        'tee_height': _nullIfBlank(_shotTeeHeightController.text),
        'ball_type': _nullIfBlank(_shotBallTypeController.text),
        'swing_type': _nullIfBlank(_shotSwingTypeController.text),
        'target_distance': _doubleOrNull(_shotTargetDistanceController.text),
      },
    );
    _shotNotesController.clear();
    _shotPenaltiesController.text = '0';
    _shotPuttsController.text = '0';
    await _refreshWorkspace();
    _showMessage('Shot entry saved.');
  }

  Future<void> _updateCurrentHole(int holeNumber, {String source = 'manual'}) async {
    if (_roundId == null) return;

    await _apiClient.postJson(
      '/rounds/$_roundId/current-hole',
      body: {'hole_number': holeNumber, 'source': source},
    );
    await _refreshWorkspace();
  }

  Future<void> _simulateGpsToNextHole() async {
    if (_roundId == null) return;
    final nextHole = _findHole(_currentHoleNumber + 1);
    if (nextHole == null) {
      _showMessage('No next hole available.');
      return;
    }

    await _apiClient.postJson(
      '/rounds/$_roundId/location',
      body: {
        'latitude': nextHole['tee_latitude'],
        'longitude': nextHole['tee_longitude'],
        'source': 'foreground_gps',
      },
    );
    await _refreshWorkspace();
    _showMessage('Foreground GPS moved the workspace to hole ${nextHole['hole_number']}.');
  }

  Future<void> _completeHole() async {
    if (_roundId == null) return;

    await _apiClient.postJson('/rounds/$_roundId/holes/$_currentHoleNumber/complete');
    await _refreshWorkspace();
    _showMessage('Hole $_currentHoleNumber marked complete.');
  }

  Map<String, dynamic>? _findHole(int holeNumber) {
    for (final hole in _holeStates) {
      if (hole['hole_number'] == holeNumber) {
        return hole;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_error!, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _bootstrap,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final currentHole = _findHole(_currentHoleNumber);
    final guidance = _guidance ?? const <String, dynamic>{};
    final summary = _workspace?['summary'] as Map<String, dynamic>? ?? const {};

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Golf Edge Round Workspace'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Scorecard'),
              Tab(text: 'Current Hole'),
              Tab(text: 'Controls'),
              Tab(text: 'Guidance'),
            ],
          ),
          actions: [
            IconButton(
              onPressed: _refreshWorkspace,
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh workspace',
            ),
          ],
        ),
        body: Column(
          children: [
            _WorkspaceHeader(
              courseName: _workspace?['course_name'] as String? ?? 'Round',
              roundId: _roundId ?? 'n/a',
              currentHoleNumber: _currentHoleNumber,
              currentHoleStatus: _workspace?['current_hole_status'] as String? ?? 'ACTIVE',
              totalStrokes: summary['total_strokes'] as int? ?? 0,
              totalPenalties: summary['total_penalties'] as int? ?? 0,
              totalPutts: summary['total_putts'] as int? ?? 0,
              onPreviousHole: _currentHoleNumber > 1
                  ? () => _updateCurrentHole(_currentHoleNumber - 1)
                  : null,
              onNextHole: _currentHoleNumber < 18
                  ? () => _updateCurrentHole(_currentHoleNumber + 1)
                  : null,
              onSimulateGps: _simulateGpsToNextHole,
              onCompleteHole: _completeHole,
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildScorecardTab(),
                  _buildCurrentHoleTab(currentHole),
                  _buildControlsTab(),
                  _buildGuidanceTab(currentHole, guidance),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScorecardTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Hole')),
                DataColumn(label: Text('Par')),
                DataColumn(label: Text('Yards')),
                DataColumn(label: Text('Status')),
                DataColumn(label: Text('Strokes')),
                DataColumn(label: Text('Penalties')),
                DataColumn(label: Text('Putts')),
                DataColumn(label: Text('Notes')),
              ],
              rows: _holeStates
                  .map(
                    (hole) => DataRow(
                      cells: [
                        DataCell(Text('${hole['hole_number']}')),
                        DataCell(Text('${hole['par']}')),
                        DataCell(Text('${hole['yardage']}')),
                        DataCell(Text(_stringOrEmpty(hole['status']))),
                        DataCell(Text('${hole['strokes']}')),
                        DataCell(Text('${hole['penalties']}')),
                        DataCell(Text('${hole['putts']}')),
                        DataCell(
                          SizedBox(
                            width: 220,
                            child: Text(_stringOrEmpty(hole['notes'])),
                          ),
                        ),
                      ],
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Recent shot log',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                for (final shot in _recentShots)
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      'Hole ${shot['hole_number']} · Shot ${shot['sequence_number']} · ${_stringOrEmpty(shot['club_used'], fallback: 'Manual')}',
                    ),
                    subtitle: Text(
                      'Lie ${_stringOrEmpty(shot['lie'], fallback: 'n/a')} · Putts ${shot['putts']} · Penalties ${shot['penalties']}',
                    ),
                    trailing: Text(_stringOrEmpty(shot['suggestion_source'])),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCurrentHoleTab(Map<String, dynamic>? currentHole) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 1000;
        final form = _buildShotEntryForm(currentHole);
        final details = _buildHoleDetailsCard(currentHole);
        if (isWide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: form),
              Expanded(child: details),
            ],
          );
        }
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            form,
            const SizedBox(height: 16),
            details,
          ],
        );
      },
    );
  }

  Widget _buildShotEntryForm(Map<String, dynamic>? currentHole) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Interactive score entry for hole $_currentHoleNumber',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _LabeledField(label: 'Club used', controller: _shotClubController),
                _LabeledField(label: 'Lie', controller: _shotLieController),
                _LabeledField(
                  label: 'Penalties',
                  controller: _shotPenaltiesController,
                  keyboardType: TextInputType.number,
                ),
                _LabeledField(
                  label: 'Putts',
                  controller: _shotPuttsController,
                  keyboardType: TextInputType.number,
                ),
                _LabeledField(label: 'Tee used', controller: _shotTeeUsedController),
                _LabeledField(label: 'Tee height', controller: _shotTeeHeightController),
                _LabeledField(label: 'Ball type', controller: _shotBallTypeController),
                _LabeledField(label: 'Swing type', controller: _shotSwingTypeController),
                _LabeledField(
                  label: 'Radar to ball',
                  controller: _shotTargetDistanceController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _shotNotesController,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Round notes',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                FilledButton.icon(
                  onPressed: _saveShot,
                  icon: const Icon(Icons.add_task),
                  label: const Text('Save shot'),
                ),
                OutlinedButton.icon(
                  onPressed: _simulateGpsToNextHole,
                  icon: const Icon(Icons.gps_fixed),
                  label: const Text('Use foreground GPS'),
                ),
              ],
            ),
            if (currentHole != null) ...[
              const SizedBox(height: 16),
              Text(
                'Hole-aware context: ${_stringOrEmpty(currentHole['fairway_aim'])}',
              ),
              const SizedBox(height: 8),
              Text(_stringOrEmpty(currentHole['hazard_summary'])),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHoleDetailsCard(Map<String, dynamic>? currentHole) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current hole status',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            if (currentHole == null)
              const Text('No hole data available.')
            else ...[
              Text(
                'Hole ${currentHole['hole_number']} · Par ${currentHole['par']} · ${currentHole['yardage']} yards',
              ),
              const SizedBox(height: 8),
              Text('State: ${_stringOrEmpty(currentHole['status'])}'),
              const SizedBox(height: 8),
              Text('Fairway aim: ${_stringOrEmpty(currentHole['fairway_aim'])}'),
              const SizedBox(height: 8),
              Text('Hazards: ${_stringOrEmpty(currentHole['hazard_summary'])}'),
              const SizedBox(height: 8),
              Text(
                'Score so far · strokes ${currentHole['strokes']} · penalties ${currentHole['penalties']} · putts ${currentHole['putts']}',
              ),
            ],
            const SizedBox(height: 16),
            Text(
              'Manual hole navigation',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final hole in _holeStates)
                  ChoiceChip(
                    label: Text('${hole['hole_number']}'),
                    selected: hole['hole_number'] == _currentHoleNumber,
                    onSelected: (_) => _updateCurrentHole(hole['hole_number'] as int),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mevo / FS Golf control panel',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _LabeledField(
                      label: 'Selected club',
                      controller: _controlClubController,
                    ),
                    _LabeledField(
                      label: 'Radar-to-ball distance',
                      controller: _controlDistanceController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                    _LabeledField(
                      label: 'Ball type',
                      controller: _controlBallTypeController,
                    ),
                    _LabeledField(
                      label: 'Tee used',
                      controller: _controlTeeUsedController,
                    ),
                    _LabeledField(
                      label: 'Tee height',
                      controller: _controlTeeHeightController,
                    ),
                    _LabeledField(
                      label: 'Swing type',
                      controller: _controlSwingTypeController,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _saveControls,
                  icon: const Icon(Icons.settings_remote),
                  label: const Text('Update controls'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Manual-first workflow: control values are saved separately from raw Mevo observations and become default suggestions for shot entry, but the scorecard can still override them at any time.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGuidanceTab(
    Map<String, dynamic>? currentHole,
    Map<String, dynamic> guidance,
  ) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Find-my-ball assistant',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                Text(
                  _stringOrEmpty(
                    guidance['message'],
                    fallback: 'Guidance will appear here when the workspace is loaded.',
                  ),
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 12),
                Text(
                  'Source: ${_stringOrEmpty(guidance['source'], fallback: 'hole_map')}',
                ),
                if (guidance['next_hole_number'] != null) ...[
                  const SizedBox(height: 8),
                  Text('Next hole preview: ${guidance['next_hole_number']}'),
                ],
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _simulateGpsToNextHole,
                  icon: const Icon(Icons.navigation),
                  label: const Text('Preload next hole with GPS'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hole context',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                Text('Fairway aim: ${_stringOrEmpty(currentHole?['fairway_aim'])}'),
                const SizedBox(height: 8),
                Text('Hazards: ${_stringOrEmpty(currentHole?['hazard_summary'])}'),
                const SizedBox(height: 8),
                Text(
                  'Tee coordinates: ${_stringOrEmpty(currentHole?['tee_latitude'])}, ${_stringOrEmpty(currentHole?['tee_longitude'])}',
                ),
                const SizedBox(height: 8),
                Text(
                  'Green coordinates: ${_stringOrEmpty(currentHole?['green_latitude'])}, ${_stringOrEmpty(currentHole?['green_longitude'])}',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String _stringOrEmpty(Object? value, {String fallback = ''}) {
    if (value == null) return fallback;
    return '$value';
  }

  String? _nullIfBlank(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    return trimmed;
  }

  int _intOrZero(String value) {
    return int.tryParse(value.trim()) ?? 0;
  }

  double? _doubleOrNull(String value) {
    return double.tryParse(value.trim());
  }
}

class _WorkspaceHeader extends StatelessWidget {
  const _WorkspaceHeader({
    required this.courseName,
    required this.roundId,
    required this.currentHoleNumber,
    required this.currentHoleStatus,
    required this.totalStrokes,
    required this.totalPenalties,
    required this.totalPutts,
    required this.onPreviousHole,
    required this.onNextHole,
    required this.onSimulateGps,
    required this.onCompleteHole,
  });

  final String courseName;
  final String roundId;
  final int currentHoleNumber;
  final String currentHoleStatus;
  final int totalStrokes;
  final int totalPenalties;
  final int totalPutts;
  final VoidCallback? onPreviousHole;
  final VoidCallback? onNextHole;
  final VoidCallback onSimulateGps;
  final VoidCallback onCompleteHole;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          runSpacing: 12,
          spacing: 16,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  courseName,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 4),
                Text('Round $roundId · Hole $currentHoleNumber · $currentHoleStatus'),
                const SizedBox(height: 4),
                Text(
                  'Total strokes $totalStrokes · Penalties $totalPenalties · Putts $totalPutts',
                ),
              ],
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: onPreviousHole,
                  icon: const Icon(Icons.chevron_left),
                  label: const Text('Previous hole'),
                ),
                OutlinedButton.icon(
                  onPressed: onNextHole,
                  icon: const Icon(Icons.chevron_right),
                  label: const Text('Next hole'),
                ),
                OutlinedButton.icon(
                  onPressed: onSimulateGps,
                  icon: const Icon(Icons.gps_fixed),
                  label: const Text('Foreground GPS'),
                ),
                FilledButton.icon(
                  onPressed: onCompleteHole,
                  icon: const Icon(Icons.flag),
                  label: const Text('Complete hole'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({
    required this.label,
    required this.controller,
    this.keyboardType,
  });

  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}
