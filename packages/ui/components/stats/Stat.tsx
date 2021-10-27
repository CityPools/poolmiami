import * as React from 'react'
import { Box, BoxProps, Stack, useColorModeValue } from '@chakra-ui/react'

interface StatProps extends BoxProps {
  title: string
  value: string
}

const Stat = (props: StatProps) => {
  const { title, value, ...rest } = props
  return (
    <Stack
      direction="column-reverse"
      maxW="12rem"
      mx="auto"
      as="dl"
      textAlign="center"
      {...rest}
    >
      <Box
        as="dt"
        color={useColorModeValue('gray.600', 'whiteAlpha.700')}
        fontWeight="medium"
      >
        {title}
      </Box>
      <Box
        as="dd"
        fontSize="6xl"
        fontWeight="extrabold"
        color={useColorModeValue('blue.500', 'blue.300')}
      >
        {value}
      </Box>
    </Stack>
  )
}

export default Stat
