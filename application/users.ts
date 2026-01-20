export async function fetchProfile(userId: string) {
  // placeholder remote callfdfsdfsdfdsfsd
  return { id: userId };
}

export async function loadProfiles(users: Array<{ id: string }>) {
  // BAD: chatty call inside loop (DevX should flag)
  const results = [];
  for (const user of users) {
    const profile = await fetchProfile(user.id);
    results.push(profile);
  }
  return results;
}
