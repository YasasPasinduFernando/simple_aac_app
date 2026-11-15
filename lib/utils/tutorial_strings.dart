import '../models/tutorial_step.dart';

class TutorialStrings {
  // --- Welcome Sheet Strings ---

  static String getWelcomeTitle(String lang) {
    switch (lang) {
      case 'si':
        return 'Simple AAC වෙත සාදරයෙන් පිළිගනිමු!';
      case 'ta':
        return 'Simple AAC-க்கு நல்வரவு!';
      case 'en':
      default:
        return 'Welcome to Simple AAC Sri Lanka!';
    }
  }

  static String getWelcomeDesc(String lang) {
    switch (lang) {
      case 'si':
        return 'සන්නිවේදන පුවරුව භාවිතය, නව කාඩ්පත් එක්කිරීම සහ සැකසුම් පහසුවෙන් ඉගෙන ගැනීමට කෙටි අන්තර්ක්‍රියාකාරී චාරිකාවක් අරඹමුද?';
      case 'ta':
        return 'தொடர்பு பலகையைப் பயன்படுத்துவது, புதிய அட்டைகளைச் சேர்ப்பது மற்றும் அமைப்புகளைப் பற்றி அறிய விரைவான வழிகாட்டியைத் தொடங்கலாமா?';
      case 'en':
      default:
        return 'Would you like a quick interactive tour to learn how to speak with cards, customize the board, and add your own words?';
    }
  }

  static String getStartTourLabel(String lang) {
    switch (lang) {
      case 'si':
        return 'කෙටි චාරිකාව අරඹන්න';
      case 'ta':
        return 'விரைவு பயணத்தைத் தொடங்கு';
      case 'en':
      default:
        return 'Start Quick Tour';
    }
  }

  static String getNotNowLabel(String lang) {
    switch (lang) {
      case 'si':
        return 'දැනට අවශ්‍ය නැත';
      case 'ta':
        return 'இப்போது வேண்டாம்';
      case 'en':
      default:
        return 'Not Now';
    }
  }

  // --- Common Buttons ---

  static String getSkipLabel(String lang) {
    switch (lang) {
      case 'si':
        return 'මඟහරින්න';
      case 'ta':
        return 'தவிர்';
      case 'en':
      default:
        return 'Skip';
    }
  }

  static String getBackLabel(String lang) {
    switch (lang) {
      case 'si':
        return 'පෙර';
      case 'ta':
        return 'முந்தையது';
      case 'en':
      default:
        return 'Back';
    }
  }

  static String getNextLabel(String lang) {
    switch (lang) {
      case 'si':
        return 'ඊළඟ';
      case 'ta':
        return 'அடுத்தது';
      case 'en':
      default:
        return 'Next';
    }
  }

  static String getFinishLabel(String lang) {
    switch (lang) {
      case 'si':
        return 'අවසන් කරන්න';
      case 'ta':
        return 'முடிக்கவும்';
      case 'en':
      default:
        return 'Finish';
    }
  }

  // --- Step Titles & Descriptions ---

  static String getStepTitle(TutorialStepType type, String lang) {
    switch (type) {
      case TutorialStepType.openMenu:
        switch (lang) {
          case 'si':
            return 'මෙනුව විවෘත කරන්න';
          case 'ta':
            return 'மெனுவைத் திறக்கவும்';
          case 'en':
          default:
            return 'Open App Menu';
        }

      case TutorialStepType.drawerExplore:
        switch (lang) {
          case 'si':
            return 'සැකසුම් ලාච්චුව';
          case 'ta':
            return 'அமைப்புகள் இழுப்பறை';
          case 'en':
          default:
            return 'Settings Drawer';
        }

      case TutorialStepType.enableEditMode:
        switch (lang) {
          case 'si':
            return 'සංස්කරණ ප්‍රකාරය';
          case 'ta':
            return 'திருத்தும் பயன்முறை';
          case 'en':
          default:
            return 'Enable Edit Mode';
        }

      case TutorialStepType.addNewCard:
        switch (lang) {
          case 'si':
            return 'නව කාඩ්පතක් එක් කරන්න';
          case 'ta':
            return 'புதிய அட்டையைச் சேர்க்கவும்';
          case 'en':
          default:
            return 'Add New Card';
        }

      case TutorialStepType.chooseMedia:
        switch (lang) {
          case 'si':
            return 'පින්තූරයක් තෝරන්න';
          case 'ta':
            return 'படத்தைத் தேர்வுசெய்க';
          case 'en':
          default:
            return 'Choose Picture';
        }

      case TutorialStepType.multilingualLabels:
        switch (lang) {
          case 'si':
            return 'භාෂා ත්‍රිත්ව ලේබල්';
          case 'ta':
            return 'மும்மொழி பெயர்கள்';
          case 'en':
          default:
            return 'Trilingual Labels';
        }

      case TutorialStepType.voiceRecording:
        switch (lang) {
          case 'si':
            return 'හඬ පටිගත කිරීම';
          case 'ta':
            return 'குரல் பதிவு';
          case 'en':
          default:
            return 'Record Voice (Optional)';
        }

      case TutorialStepType.saveCard:
        switch (lang) {
          case 'si':
            return 'කාඩ්පත සුරකින්න';
          case 'ta':
            return 'அட்டையைச் சேமிக்கவும்';
          case 'en':
          default:
            return 'Save Your Card';
        }

      case TutorialStepType.testNewCard:
        switch (lang) {
          case 'si':
            return 'කාඩ්පත තට්ටු කර අසන්න!';
          case 'ta':
            return 'அட்டையைத் தட்டி கேளுங்கள்!';
          case 'en':
          default:
            return 'Tap to Hear Speech!';
        }

      case TutorialStepType.completed:
        switch (lang) {
          case 'si':
            return 'සුබ පැතුම්!';
          case 'ta':
            return 'வாழ்த்துகள்!';
          case 'en':
          default:
            return 'Awesome Job!';
        }
    }
  }

  static String getStepDesc(TutorialStepType type, String lang) {
    switch (type) {
      case TutorialStepType.openMenu:
        switch (lang) {
          case 'si':
            return 'සැකසුම්, හඬ තේරීම් සහ සංස්කරණ විකල්ප වෙත පිවිසීමට ඉහළ වම්පස ඇති මෙනු බොත්තම තට්ටු කරන්න.';
          case 'ta':
            return 'அமைப்புகள் மற்றும் திருத்தும் விருப்பங்களைக் காண மேல் இடது மூலையிலுள்ள மெனு பொத்தானைத் தட்டவும்.';
          case 'en':
          default:
            return 'Tap the menu button at the top left to open Settings, speech controls, and card editor options.';
        }

      case TutorialStepType.drawerExplore:
        switch (lang) {
          case 'si':
            return 'ලාච්චුව වඩාත් ඉඩ ඇතිව බැලීමට වමට අදින්න (Swipe left) හෝ ඉහළ ඇති ඊතලය ඔබන්න.';
          case 'ta':
            return 'முழுமையாகக் காண இடதுபுறமாக ஸ்வைப் செய்யவும் அல்லது மேல் அம்புக்குறியைத் தட்டவும்.';
          case 'en':
          default:
            return 'Swipe left or tap the expand arrow in the header to expand the drawer for a spacious view.';
        }

      case TutorialStepType.enableEditMode:
        switch (lang) {
          case 'si':
            return 'නව වචන එක් කිරීමට හෝ පුවරුව සංවිධානය කිරීමට "Enable Edit Mode" මත තට්ටු කරන්න.';
          case 'ta':
            return 'புதிய சொற்களைச் சேர்க்க அல்லது மாற்ற "Enable Edit Mode" என்பதைத் தட்டவும்.';
          case 'en':
          default:
            return 'Tap "Enable Edit Mode" to unlock board customization and add new communication cards.';
        }

      case TutorialStepType.addNewCard:
        switch (lang) {
          case 'si':
            return 'නව සන්නිවේදන කාඩ්පතක් නිර්මාණය කිරීම ආරම්භ කිරීමට "+ Add New" බොත්තම ඔබන්න.';
          case 'ta':
            return 'புதிய தொடர்பு அட்டையை உருவாக்க "+ Add New" பொத்தானைத் தட்டவும்.';
          case 'en':
          default:
            return 'Tap "+ Add New" in the top editing toolbar to start creating your personalized card.';
        }

      case TutorialStepType.chooseMedia:
        switch (lang) {
          case 'si':
            return 'Smart Search, ගැලරිය හෝ කැමරාව මඟින් පින්තූරයක් තෝරන්න. (Smart Search සඳහා අන්තර්ජාලය අවශ්‍ය වේ)';
          case 'ta':
            return 'கேமரா, கேலரி அல்லது ஸ்மார்ட் தேடலைப் பயன்படுத்தி படத்தைத் தேர்வுசெய்யவும்.';
          case 'en':
          default:
            return 'Choose a picture using Smart Search, your Photo Gallery, Camera, or an animated GIF.';
        }

      case TutorialStepType.multilingualLabels:
        switch (lang) {
          case 'si':
            return 'කාඩ්පත සඳහා ඉංග්‍රීසි, සිංහල සහ දෙමළ නම් ඇතුළත් කරන්න. පහළ ඇති AI යෝජනා මතද තට්ටු කළ හැක.';
          case 'ta':
            return 'ஆங்கிலம், சிங்களம் மற்றும் தமிழில் பெயர்களை உள்ளிடவும். கீழ் தோன்றும் பரிந்துரைகளையும் தேர்வுசெய்யலாம்.';
          case 'en':
          default:
            return 'Enter trilingual labels (English, Sinhala, Tamil) or tap auto-detected object tags below.';
        }

      case TutorialStepType.voiceRecording:
        switch (lang) {
          case 'si':
            return 'ස්වයංක්‍රීය කථනය වෙනුවට ඔබේම හඬින් වචනය උච්චාරණය කිරීමට "Record Voice" භාවිතා කළ හැක.';
          case 'ta':
            return 'இயற்கையான உச்சரிப்புக்காக உங்கள் சொந்தக் குரலையும் பதிவுசெய்து இணைக்கலாம்.';
          case 'en':
          default:
            return 'Optionally record a familiar voice for this card, or let the app speak with offline text-to-speech.';
        }

      case TutorialStepType.saveCard:
        switch (lang) {
          case 'si':
            return 'සියල්ල සූදානම් වූ පසු, කාඩ්පත පුවරුවට එක් කිරීමට "Save Card" බොත්තම ඔබන්න.';
          case 'ta':
            return 'அட்டையை உங்கள் பலகையில் சேர்க்க "Save Card" என்பதைத் தட்டவும்.';
          case 'en':
          default:
            return 'When you are ready, tap "Save Card" to add your new word to the active AAC board.';
        }

      case TutorialStepType.testNewCard:
        switch (lang) {
          case 'si':
            return 'විශිෂ්ටයි! ඔබ සෑදූ නව කාඩ්පත දැන් පුවරුවේ ඇත. එය තට්ටු කර ශබ්දය අසන්න!';
          case 'ta':
            return 'அற்புதம்! நீங்கள் உருவாக்கிய அட்டை பலகையில் உள்ளது. உச்சரிப்பைக் கேட்க அதைத் தட்டவும்!';
          case 'en':
          default:
            return 'Great! Your new card is now on the board. Tap it to hear the spoken pronunciation!';
        }

      case TutorialStepType.completed:
        switch (lang) {
          case 'si':
            return 'ඔබ සාර්ථකව ඔබේ පළමු කාඩ්පත සාදන ලදී! ඔබට අවශ්‍ය ඕනෑම විටෙක Settings > Quick Tour මඟින් මෙම මඟපෙන්වීම නැවත බැලිය හැක.';
          case 'ta':
            return 'நீங்கள் வெற்றிகரமாக உங்கள் அட்டையை உருவாக்கிவிட்டீர்கள்! அமைப்புகள் மெனுவிலிருந்து எந்த நேரத்திலும் இதை மீண்டும் காணலாம்.';
          case 'en':
          default:
            return 'You have mastered the basics of Simple AAC! You can replay this interactive guide anytime from Settings > Quick Tour.';
        }
    }
  }

  // --- Mini Guides Titles & Descriptions ---

  static String getMiniGuidesTitle(String lang) {
    switch (lang) {
      case 'si':
        return 'උපකාරක මාර්ගෝපදේශ';
      case 'ta':
        return 'உதவி வழிகாட்டிகள்';
      case 'en':
      default:
        return 'Help & Feature Guides';
    }
  }

  static String getPinGuideTitle(String lang) {
    switch (lang) {
      case 'si':
        return 'ආරක්ෂක PIN අංකය (Caregiver PIN)';
      case 'ta':
        return 'பாதுகாப்பு PIN (Caregiver PIN)';
      case 'en':
      default:
        return 'Caregiver PIN Protection';
    }
  }

  static String getPinGuideDesc(String lang) {
    switch (lang) {
      case 'si':
        return 'දරුවන් අතින් අහඹු ලෙස කාඩ්පත් වෙනස්වීම වැළැක්වීමට Settings හි Caregiver PIN සක්‍රිය කරන්න. එය සක්‍රිය කළ විට සංස්කරණ ප්‍රකාරයට පිවිසීමට අංක 4ක කේතයක් ඇතුළත් කළ යුතුය.';
      case 'ta':
        return 'குழந்தைகள் தற்செயலாக அமைப்புகளை மாற்றுவதைத் தடுக்க Caregiver PIN-ஐ இயக்கவும். இது திருத்தும் பயன்முறைக்கு 4 இலக்க குறியீட்டைக் கேட்கும்.';
      case 'en':
      default:
        return 'Protect your board layout by enabling the Caregiver PIN in Settings. When enabled, a 4-digit PIN is required before unlocking edit mode.';
    }
  }

  static String getBackupGuideTitle(String lang) {
    switch (lang) {
      case 'si':
        return 'දත්ත උපස්ථ සහ ප්‍රතිසාධනය (Backup & Restore)';
      case 'ta':
        return 'காப்புப்பிரதி மற்றும் மீட்டமை (Backup & Restore)';
      case 'en':
      default:
        return 'Backup & Restore Data';
    }
  }

  static String getBackupGuideDesc(String lang) {
    switch (lang) {
      case 'si':
        return 'ඔබේ සියලුම අභිරුචි කාඩ්පත්, හඬ පටිගත කිරීම් සහ සැකසුම් සුරක්ෂිතව තබා ගැනීමට හෝ වෙනත් දුරකථනයකට මාරු කිරීමට Settings හි Backup / Export විකල්පය භාවිතා කරන්න.';
      case 'ta':
        return 'உங்கள் தனிப்பயன் அட்டைகள் மற்றும் குரல் பதிவுகளைப் பாதுகாக்க அல்லது மற்றொரு சாதனத்திற்கு மாற்ற Backup / Export அம்சத்தைப் பயன்படுத்தவும்.';
      case 'en':
      default:
        return 'Safely export all your custom cards, recorded voices, and board settings into a single backup file or transfer them to another device.';
    }
  }

  static String getPermissionsGuideTitle(String lang) {
    switch (lang) {
      case 'si':
        return 'යෙදුම් අවසර (App Permissions)';
      case 'ta':
        return 'பயன்பாட்டு அனுமதிகள் (Permissions)';
      case 'en':
      default:
        return 'Permissions & Privacy';
    }
  }

  static String getPermissionsGuideDesc(String lang) {
    switch (lang) {
      case 'si':
        return 'ඡායාරූප ගැනීමට කැමරා අවසරයද, ඔබේ හඬ එක් කිරීමට මයික්‍රෆෝන අවසරයද අවශ්‍ය වේ. යෙදුම 100% නොබැඳිව ක්‍රියාකරන අතර කිසිදු පුද්ගලික දත්තයක් අන්තර්ජාලයට නොයවයි.';
      case 'ta':
        return 'படங்களை எடுக்க கேமரா அனுமதியும், குரலைப் பதிவுசெய்ய மைக்ரோஃபோன் அனுமதியும் தேவை. பயன்பாடு 100% பாதுகாப்பானது.';
      case 'en':
      default:
        return 'Camera permission is needed for photos and Microphone for recording voice. The app operates offline and never uploads personal photos or recordings.';
    }
  }

  static String getSmartSearchGuideTitle(String lang) {
    switch (lang) {
      case 'si':
        return 'ස්මාර්ට් සෙවුම සහ රහස්‍යතාව (Smart Search)';
      case 'ta':
        return 'ஸ்மார்ட் தேடல் மற்றும் தனியுரிமை';
      case 'en':
      default:
        return 'Smart Search & Privacy';
    }
  }

  static String getSmartSearchGuideDesc(String lang) {
    switch (lang) {
      case 'si':
        return 'Online Features සක්‍රිය කළ විට දරුවන්ට සුදුසු ආරක්ෂිත ළමා පින්තූර සොයාගත හැක. මෙය අක්‍රිය කළ විට යෙදුම සම්පූර්ණයෙන්ම Offline වන අතර කිසිදු සබඳතාවක් නොපවත්වයි.';
      case 'ta':
        return 'ஆன்லைன் வசதி இயக்கப்பட்டால் குழந்தைகளுக்கு ஏற்ற படங்களைத் தேடலாம். முடக்கப்பட்டால் பயன்பாடு முற்றிலும் ஆஃப்லைனில் இருக்கும்.';
      case 'en':
      default:
        return 'Online Features allow searching child-safe card images. When toggled OFF in Settings, the app becomes strictly 100% offline with zero network calls.';
    }
  }

  static String getGifGuideTitle(String lang) {
    switch (lang) {
      case 'si':
        return 'සජීවිකරණ GIF සහ කෙටි වීඩියෝ';
      case 'ta':
        return 'GIF மற்றும் குறுகிய வீடியோக்கள்';
      case 'en':
      default:
        return 'Animated GIFs & Short Videos';
    }
  }

  static String getGifGuideDesc(String lang) {
    switch (lang) {
      case 'si':
        return 'ක්‍රියා පද (Actions - e.g., දුවනවා, පනිනවා) හෝ හැඟීම් පෙන්වීමට තත්පර 30 දක්වා වූ කෙටි සජීවිකරණ GIF හෝ වීඩියෝ කාඩ්පතට ඇතුළත් කළ හැක.';
      case 'ta':
        return 'செயல்களை (எ.கா., ஓடுதல், குதித்தல்) விளக்குவதற்கு 30 வினாடிகள் வரையிலான GIF அல்லது வீடியோக்களைச் சேர்க்கலாம்.';
      case 'en':
      default:
        return 'Bring dynamic concepts and actions to life by adding animated GIFs or short video clips up to 30 seconds to any card.';
    }
  }
}
