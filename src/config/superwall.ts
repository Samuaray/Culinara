import Superwall from '@superwall/react-native-superwall';

const SUPERWALL_API_KEY = process.env.EXPO_PUBLIC_SUPERWALL_API_KEY || '';

export const initializeSuperwall = async () => {
  if (!SUPERWALL_API_KEY) {
    console.warn('Superwall API key is missing. Please add it to your .env file.');
    return;
  }

  try {
    await Superwall.configure(SUPERWALL_API_KEY, {
      logging: {
        level: __DEV__ ? 'debug' : 'warn',
      },
    });

    console.log('Superwall initialized successfully');
  } catch (error) {
    console.error('Failed to initialize Superwall:', error);
  }
};

export const presentPaywall = async (event: string) => {
  try {
    await Superwall.register(event);
  } catch (error) {
    console.error('Error presenting paywall:', error);
  }
};

export const setUserAttributes = async (attributes: Record<string, any>) => {
  try {
    await Superwall.setUserAttributes(attributes);
  } catch (error) {
    console.error('Error setting user attributes:', error);
  }
};

export const identify = async (userId: string) => {
  try {
    await Superwall.identify(userId);
  } catch (error) {
    console.error('Error identifying user:', error);
  }
};

export const reset = async () => {
  try {
    await Superwall.reset();
  } catch (error) {
    console.error('Error resetting Superwall:', error);
  }
};
