import { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { api } from '../lib/api';

interface Genre {
  id: string;
  name: string;
  imageUrl?: string | null;
}

export default function GenresPage() {
  const queryClient = useQueryClient();
  const [editingId, setEditingId] = useState<string | null>(null);
  const [editImageUrl, setEditImageUrl] = useState('');

  const { data: genres, isLoading } = useQuery({
    queryKey: ['genres'],
    queryFn: async () => {
      const res = await api.get<{ genres: Genre[] }>('/genres');
      return res.data.genres;
    },
  });

  const updateGenre = useMutation({
    mutationFn: async ({ id, imageUrl }: { id: string; imageUrl: string }) => {
      await api.patch(`/admin/genres/${id}`, { imageUrl: imageUrl || null });
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['genres'] });
      setEditingId(null);
    },
  });

  if (isLoading) return <div className="p-8">Loading genres...</div>;

  return (
    <div className="p-8">
      <div className="flex justify-between items-center mb-8">
        <h1 className="text-2xl font-bold">Manage Genres</h1>
      </div>

      <div className="bg-white rounded-lg shadow overflow-hidden">
        <table className="min-w-full divide-y divide-gray-200">
          <thead className="bg-gray-50">
            <tr>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Name
              </th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Image URL
              </th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Preview
              </th>
              <th className="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">
                Actions
              </th>
            </tr>
          </thead>
          <tbody className="bg-white divide-y divide-gray-200">
            {genres?.map((genre) => (
              <tr key={genre.id}>
                <td className="px-6 py-4 whitespace-nowrap font-medium text-gray-900">
                  {genre.name}
                </td>
                <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500 max-w-[300px] truncate">
                  {editingId === genre.id ? (
                    <input
                      type="url"
                      className="border rounded px-2 py-1 w-full"
                      value={editImageUrl}
                      onChange={(e) => setEditImageUrl(e.target.value)}
                      placeholder="https://..."
                    />
                  ) : (
                    genre.imageUrl || <span className="text-gray-400 italic">Not set</span>
                  )}
                </td>
                <td className="px-6 py-4 whitespace-nowrap">
                  {genre.imageUrl ? (
                    <img
                      src={genre.imageUrl}
                      alt={genre.name}
                      className="h-10 w-24 object-cover rounded shadow-sm"
                    />
                  ) : (
                    <div className="h-10 w-24 bg-gray-100 rounded flex items-center justify-center text-xs text-gray-400">
                      No Image
                    </div>
                  )}
                </td>
                <td className="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
                  {editingId === genre.id ? (
                    <div className="flex justify-end gap-2">
                      <button
                        onClick={() => setEditingId(null)}
                        className="text-gray-600 hover:text-gray-900"
                        disabled={updateGenre.isPending}
                      >
                        Cancel
                      </button>
                      <button
                        onClick={() => updateGenre.mutate({ id: genre.id, imageUrl: editImageUrl })}
                        className="text-blue-600 hover:text-blue-900"
                        disabled={updateGenre.isPending}
                      >
                        {updateGenre.isPending ? 'Saving...' : 'Save'}
                      </button>
                    </div>
                  ) : (
                    <button
                      onClick={() => {
                        setEditingId(genre.id);
                        setEditImageUrl(genre.imageUrl || '');
                      }}
                      className="text-blue-600 hover:text-blue-900"
                    >
                      Edit Image
                    </button>
                  )}
                </td>
              </tr>
            ))}
            {!genres?.length && (
              <tr>
                <td colSpan={4} className="px-6 py-8 text-center text-gray-500">
                  No genres found.
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
}
