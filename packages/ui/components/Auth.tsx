import React from 'react';
import { Button } from '@chakra-ui/react';
import { useConnect, userSessionState } from '../lib/auth';
import { useAtom } from 'jotai';

// Authentication button adapting to status

export default function Auth() {
  console.log('User Session State', userSessionState);
  const { handleOpenAuth } = useConnect();
  const { handleSignOut } = useConnect();
  const [userSession] = useAtom(userSessionState);

  if (userSession?.isUserSignedIn()) {
    return (
      <Button
        size="lg"
        colorScheme="blue"
        height="14"
        px="8"
        fontSize="md"
        onClick={handleSignOut}
      >
        Log out
      </Button>
    );
  } else {
    return (
      <Button
        size="lg"
        colorScheme="blue"
        height="14"
        px="8"
        fontSize="md"
        onClick={handleOpenAuth}
      >
        Get Started Now
      </Button>
    );
  }
}