import 'package:flutter/material.dart';
import '../../app/ui/app_colors.dart';

class AvatarPickerSheet extends StatelessWidget {
  final int selectedId;
  final void Function(int id) onPick;

  const AvatarPickerSheet({
    super.key,
    required this.selectedId,
    required this.onPick,
  });

  static const List<int> _avatars = [1, 2, 3, 4];

  @override
  Widget build(BuildContext context) {
    final primaryBlue = AppColors.blue;

    final height = MediaQuery.of(context).size.height;
    final sheetHeight = height * 0.62;

    return SafeArea(
      top: false,
      child: SizedBox(
        height: sheetHeight,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          child: Column(
            children: [
              Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Wybierz avatar',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
              ),
              const SizedBox(height: 14),

              Expanded(
                child: GridView.builder(
                  itemCount: _avatars.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: 1.0,
                  ),
                  itemBuilder: (context, index) {
                    final id = _avatars[index];
                    final isSelected = id == selectedId;

                    return _AvatarTile(
                      id: id,
                      isSelected: isSelected,
                      primaryBlue: primaryBlue,
                      onTap: () => onPick(id),
                    );
                  },
                ),
              ),

              const SizedBox(height: 8),

              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Zamknij'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AvatarTile extends StatelessWidget {
  final int id;
  final bool isSelected;
  final Color primaryBlue;
  final VoidCallback onTap;

  const _AvatarTile({
    required this.id,
    required this.isSelected,
    required this.primaryBlue,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = isSelected ? primaryBlue : Colors.black.withOpacity(0.10);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: borderColor, width: isSelected ? 2.2 : 1.2),
          ),
          padding: const EdgeInsets.all(12),
          child: Stack(
            children: [
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Transform.scale(
                      scale: 1.10,
                      child: Image.asset(
                        'assets/avatars/avatar$id.png',
                        fit: BoxFit.cover,
                        filterQuality: FilterQuality.high,
                      ),
                    ),
                  ),
                ),
              ),
              if (isSelected)
                Positioned(
                  right: 6,
                  top: 6,
                  child: CircleAvatar(
                    radius: 14,
                    backgroundColor: primaryBlue,
                    child: const Icon(Icons.check, color: Colors.white, size: 18),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}