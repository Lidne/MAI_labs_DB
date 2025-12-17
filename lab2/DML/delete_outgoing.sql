DELETE FROM outgoing
WHERE id = (
  SELECT id
  FROM outgoing
  ORDER BY date ASC
  LIMIT 1
);
