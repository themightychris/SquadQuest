function scrubProfile(userProfile: { [key: string]: string | number }) {
  return {
    id: userProfile?.id,
    first_name: userProfile?.first_name,
    last_name: userProfile?.last_name,
  };
}

export { scrubProfile };
