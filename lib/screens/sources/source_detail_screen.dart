import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/source.dart';
import '../../models/group.dart';
import '../../models/quote.dart';
import '../../providers/group_provider.dart';
import '../../providers/quote_provider.dart';

class SourceDetailScreen extends ConsumerWidget {
  final Source source;

  const SourceDetailScreen({super.key, required this.source});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsAsync = ref.watch(groupProvider);

    return Scaffold(
      appBar: AppBar(title: Text(source.title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with type icon and title
            _buildHeader(context),
            const SizedBox(height: 24),

            // Basic Information
            _buildSection(context, 'Basic Information', [
              _buildInfoRow(
                'Type',
                '${source.typeIcon} ${source.typeDisplayName}',
              ),
              _buildInfoRow('Author/Creator', source.source),
              _buildInfoRow(
                'Status',
                source.statusDisplayName,
                status: source.status,
              ),
              _buildInfoRow('Created', _formatDate(source.createdAt)),
            ]),

            // Groups
            _buildGroupsSection(context, groupsAsync),

            // Dates
            _buildDatesSection(context),

            // Notes
            if (source.hasNotes) _buildNotesSection(context),

            // Quotes
            _buildQuotesSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).primaryColor.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(source.typeIcon, style: const TextStyle(fontSize: 24)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  source.title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  source.source,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    List<Widget> children,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(children: children),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, {SourceStatus? status}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: status != null ? _getStatusColor(status) : null,
                fontWeight: status != null ? FontWeight.w500 : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupsSection(
    BuildContext context,
    AsyncValue<List<Group>> groupsAsync,
  ) {
    return groupsAsync.when(
      data: (groups) {
        final sourceGroups = groups
            .where((group) => source.isInGroup(group.id))
            .toList();

        if (sourceGroups.isEmpty) {
          return _buildSection(context, 'Groups', [
            const Text(
              'No groups assigned',
              style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
            ),
          ]);
        }

        return _buildSection(context, 'Groups', [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: sourceGroups
                .map(
                  (group) => Chip(
                    label: Text(group.name),
                    backgroundColor: Colors.blue.shade50,
                    side: BorderSide(color: Colors.blue.shade200),
                  ),
                )
                .toList(),
          ),
        ]);
      },
      loading: () => _buildSection(context, 'Groups', [
        const Center(child: CircularProgressIndicator()),
      ]),
      error: (_, __) => _buildSection(context, 'Groups', [
        const Text('Error loading groups', style: TextStyle(color: Colors.red)),
      ]),
    );
  }

  Widget _buildDatesSection(BuildContext context) {
    return _buildSection(context, 'Timeline', [
      if (source.startDate != null)
        _buildInfoRow('Started', _formatDate(source.startDate!)),
      if (source.finishDate != null)
        _buildInfoRow('Finished', _formatDate(source.finishDate!)),
      if (source.startDate == null && source.finishDate == null)
        const Text(
          'No dates recorded',
          style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
        ),
    ]);
  }

  Widget _buildNotesSection(BuildContext context) {
    return _buildSection(context, 'Notes', [
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Text(source.notes!, style: const TextStyle(height: 1.5)),
      ),
    ]);
  }

  Widget _buildQuotesSection(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final quotesAsync = ref.watch(quotesBySourceProvider(source.id));

        return quotesAsync.when(
          data: (quotes) {
            if (quotes.isEmpty) {
              return _buildSection(context, 'Quotes', [
                const Text(
                  'No quotes from this source yet',
                  style: TextStyle(
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ]);
            }

            return _buildSection(context, 'Quotes (${quotes.length})', [
              ...quotes.map((quote) => _buildQuoteCard(context, quote)),
            ]);
          },
          loading: () => _buildSection(context, 'Quotes', [
            const Center(child: CircularProgressIndicator()),
          ]),
          error: (_, __) => _buildSection(context, 'Quotes', [
            const Text(
              'Error loading quotes',
              style: TextStyle(color: Colors.red),
            ),
          ]),
        );
      },
    );
  }

  Widget _buildQuoteCard(BuildContext context, Quote quote) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quote text
          Text(
            quote.quote,
            style: const TextStyle(
              fontSize: 16,
              height: 1.5,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 12),

          // Quote metadata
          Row(
            children: [
              // Page number
              if (quote.pageNumber != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Page ${quote.pageNumber}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],

              // Hashtags
              if (quote.hashtags.isNotEmpty) ...[
                Expanded(
                  child: Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: quote.hashtags
                        .map(
                          (tag) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.shade100,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '#$tag',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.green.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: 8),

          // Created date
          Text(
            'Added ${_formatDate(quote.createdAt)}',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(SourceStatus status) {
    switch (status) {
      case SourceStatus.notStarted:
        return Colors.grey;
      case SourceStatus.inProgress:
        return Colors.orange;
      case SourceStatus.completed:
        return Colors.green;
      case SourceStatus.paused:
        return Colors.blue;
      case SourceStatus.abandoned:
        return Colors.red;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
