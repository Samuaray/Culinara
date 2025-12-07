import { useEffect, useState } from 'react';
import { StatusBar } from 'expo-status-bar';
import { StyleSheet, Text, View, ActivityIndicator } from 'react-native';
import { initializeRevenueCat } from './src/config/revenuecat';
import { initializeSuperwall } from './src/config/superwall';
import { useAuth } from './src/hooks/useAuth';

export default function App() {
  const [isInitializing, setIsInitializing] = useState(true);
  const { user, loading } = useAuth();

  useEffect(() => {
    const initialize = async () => {
      try {
        // Initialize RevenueCat and Superwall
        await Promise.all([
          initializeRevenueCat(),
          initializeSuperwall(),
        ]);
      } catch (error) {
        console.error('Error initializing app:', error);
      } finally {
        setIsInitializing(false);
      }
    };

    initialize();
  }, []);

  if (isInitializing || loading) {
    return (
      <View style={styles.container}>
        <ActivityIndicator size="large" color="#007AFF" />
        <Text style={styles.loadingText}>Initializing Culinara...</Text>
      </View>
    );
  }

  return (
    <View style={styles.container}>
      <Text style={styles.title}>🍳 Culinara</Text>
      <Text style={styles.subtitle}>AI-Powered Recipe Management</Text>
      <Text style={styles.status}>
        {user ? `Logged in as: ${user.email}` : 'Not logged in'}
      </Text>
      <Text style={styles.info}>Ready to start building!</Text>
      <StatusBar style="auto" />
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#fff',
    alignItems: 'center',
    justifyContent: 'center',
    padding: 20,
  },
  title: {
    fontSize: 32,
    fontWeight: 'bold',
    marginBottom: 8,
  },
  subtitle: {
    fontSize: 18,
    color: '#666',
    marginBottom: 20,
  },
  status: {
    fontSize: 14,
    color: '#007AFF',
    marginBottom: 12,
  },
  info: {
    fontSize: 16,
    color: '#333',
  },
  loadingText: {
    marginTop: 16,
    fontSize: 16,
    color: '#666',
  },
});
