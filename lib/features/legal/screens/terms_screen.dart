import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Conditions d\'utilisation'),
        backgroundColor: isDark ? AppColors.primaryDark : Colors.white,
        foregroundColor: isDark ? Colors.white : AppColors.textPrimaryLight,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              'Bienvenue sur Footix',
              'En utilisant cette application, vous acceptez les présentes conditions d\'utilisation. '
              'Veuillez les lire attentivement avant de continuer.',
              isDark,
            ),
            
            _buildSection(
              '1. Objet de l\'application',
              'Footix est une application éducative dédiée au football. '
              'Elle propose des quiz interactifs, des thèmes variés et un classement pour tester et améliorer vos connaissances sur le football.',
              isDark,
            ),
            
            _buildSection(
              '2. Collecte et utilisation des données personnelles',
              'Conformément au Règlement Général sur la Protection des Données (RGPD) et à la loi Informatique et Libertés, '
              'nous collectons et traitons vos données personnelles de manière transparente et sécurisée.\n\n'
              '**Données collectées :**\n'
              '• Informations d\'identification : nom, prénom, adresse email\n'
              '• Données de connexion : identifiants, mot de passe (chiffré)\n'
              '• Données d\'utilisation : progression dans les quiz, scores, historique d\'apprentissage\n'
              '• Données techniques : type d\'appareil, système d\'exploitation (à des fins de compatibilité)\n\n'
              '**Finalités du traitement :**\n'
              '• Gestion de votre compte utilisateur\n'
              '• Personnalisation de votre expérience d\'apprentissage\n'
              '• Suivi de votre progression et statistiques\n'
              '• Communication relative à votre compte et à l\'application\n'
              '• Amélioration continue de nos services',
              isDark,
            ),
            
            _buildSection(
              '3. Base légale du traitement',
              'Le traitement de vos données repose sur :\n\n'
              '• **Votre consentement** : en créant un compte, vous consentez expressément au traitement de vos données\n'
              '• **L\'exécution du contrat** : le traitement est nécessaire pour vous fournir nos services\n'
              '• **Notre intérêt légitime** : amélioration de l\'application et prévention des fraudes',
              isDark,
            ),
            
            _buildSection(
              '4. Durée de conservation',
              'Vos données personnelles sont conservées pendant toute la durée de votre inscription, '
              'puis pendant une durée de 3 ans après la suppression de votre compte, conformément aux obligations légales.\n\n'
              'Les données de connexion et logs techniques sont conservés pendant 1 an.',
              isDark,
            ),
            
            _buildSection(
              '5. Vos droits',
              'Conformément au RGPD, vous disposez des droits suivants :\n\n'
              '• **Droit d\'accès** : obtenir une copie de vos données personnelles\n'
              '• **Droit de rectification** : corriger des données inexactes\n'
              '• **Droit à l\'effacement** : demander la suppression de vos données\n'
              '• **Droit à la portabilité** : recevoir vos données dans un format structuré\n'
              '• **Droit d\'opposition** : vous opposer au traitement de vos données\n'
              '• **Droit à la limitation** : limiter le traitement de vos données\n\n'
              'Pour exercer ces droits, contactez-nous à : footixcontact@gmail.com',
              isDark,
            ),
            
            _buildSection(
              '6. Sécurité des données',
              'Nous mettons en œuvre des mesures techniques et organisationnelles appropriées pour protéger vos données :\n\n'
              '• Chiffrement des données sensibles (mots de passe, communications)\n'
              '• Accès restreint aux données personnelles\n'
              '• Serveurs sécurisés hébergés dans l\'Union Européenne\n'
              '• Audits de sécurité réguliers',
              isDark,
            ),
            
            _buildSection(
              '7. Partage des données',
              'Vos données personnelles ne sont jamais vendues à des tiers.\n\n'
              'Elles peuvent être partagées avec :\n'
              '• Nos prestataires techniques (hébergement, paiement) dans le cadre strict de leurs missions\n'
              '• Les autorités compétentes sur demande légale\n\n'
              'Tout prestataire est soumis à des obligations de confidentialité strictes.',
              isDark,
            ),
            
            _buildSection(
              '8. Cookies et traceurs',
              'L\'application utilise des cookies techniques nécessaires à son fonctionnement. '
              'Aucun cookie publicitaire ou de tracking n\'est utilisé sans votre consentement explicite.',
              isDark,
            ),
            
            _buildSection(
              '9. Propriété intellectuelle',
              'Tous les contenus de l\'application (textes, quiz, images, logos) sont protégés par le droit d\'auteur. '
              'Toute reproduction ou utilisation non autorisée est interdite.',
              isDark,
            ),
            
            _buildSection(
              '10. Modification des conditions',
              'Nous nous réservons le droit de modifier ces conditions à tout moment. '
              'Vous serez informé de toute modification substantielle par notification dans l\'application.',
              isDark,
            ),
            
            _buildSection(
              '11. Contact et réclamations',
              'Pour toute question ou réclamation concernant vos données personnelles :\n\n'
              '**Email** : footixcontact@gmail.com\n\n'
              'Vous pouvez également introduire une réclamation auprès de la CNIL (Commission Nationale de l\'Informatique et des Libertés) : www.cnil.fr',
              isDark,
            ),
            
            const SizedBox(height: 20),
            
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.verified_user_rounded, color: AppColors.primary, size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'En créant un compte ou en utilisant l\'application, vous confirmez avoir lu et accepté ces conditions.',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.white : AppColors.textPrimaryLight,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            Center(
              child: Text(
                'Dernière mise à jour : Février 2026',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textMutedLight,
                ),
              ),
            ),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSection(String title, String content, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(
              fontSize: 14,
              height: 1.6,
              color: isDark ? Colors.white70 : AppColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }
}
