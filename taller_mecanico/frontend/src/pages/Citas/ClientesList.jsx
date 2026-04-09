import React, { useState, useEffect, useContext } from 'react';
import axios from 'axios';
import { AuthContext } from '../../context/AuthContext';
import { useTheme } from '../../context/ThemeContext';
import {
    Users, Search, RefreshCw, Loader2, Mail, User, AtSign
} from 'lucide-react';

export default function ClientesList() {
    const { authTokens, logoutUser } = useContext(AuthContext);
    const { isDark } = useTheme();

    const [clientes, setClientes] = useState([]);
    const [loading, setLoading] = useState(true);
    const [query, setQuery] = useState('');

    const headers = { Authorization: `Bearer ${authTokens.access}` };

    useEffect(() => {
        fetchClientes();
    }, []);

    const fetchClientes = async (q = '') => {
        setLoading(true);
        try {
            const res = await axios.get(`http://localhost:8000/api/v1/clientes/?q=${q}`, { headers });
            setClientes(res.data);
        } catch (e) {
            if (e.response?.status === 401) logoutUser();
        }
        setLoading(false);
    };

    const handleSearch = (e) => {
        const v = e.target.value;
        setQuery(v);
        fetchClientes(v);
    };

    // ── Estilos (mismo patrón que VehiculosList) ──
    const pageBg  = isDark ? 'bg-slate-900'  : 'bg-slate-50';
    const cardBg  = isDark ? 'bg-slate-800'  : 'bg-white';
    const border  = isDark ? 'border-slate-700' : 'border-slate-200';
    const textPrimary = isDark ? 'text-white'      : 'text-slate-900';
    const subText     = isDark ? 'text-slate-400'  : 'text-slate-500';
    const inputCls = `flex-1 min-w-0 px-4 py-2.5 rounded-xl border text-sm font-medium outline-none transition-all focus:ring-2 focus:ring-blue-500/30 ${
        isDark
            ? 'bg-slate-800 border-slate-700 text-white placeholder-slate-500'
            : 'bg-white border-slate-200 text-slate-900 placeholder-slate-400'
    }`;

    // Generar iniciales para avatar
    const getInitials = (cliente) => {
        const first = cliente.first_name?.[0] || '';
        const last  = cliente.last_name?.[0]  || '';
        return (first + last).toUpperCase() || cliente.username?.[0]?.toUpperCase() || '?';
    };

    // Color de avatar basado en el id del cliente
    const AVATAR_COLORS = [
        'bg-blue-500', 'bg-emerald-500', 'bg-violet-500',
        'bg-orange-500', 'bg-pink-500', 'bg-cyan-500',
    ];
    const getAvatarColor = (id) => AVATAR_COLORS[id % AVATAR_COLORS.length];

    return (
        <div className={`flex-1 w-full ${pageBg} p-6 flex flex-col min-h-full`}>

            {/* Header */}
            <div className="mb-8 flex flex-col sm:flex-row justify-between sm:items-end gap-4 shrink-0">
                <div>
                    <h2 className={`text-2xl font-bold tracking-tight flex items-center gap-2 ${textPrimary}`}>
                        <Users className="text-blue-500" /> Base de Clientes
                    </h2>
                    <p className={`text-sm mt-1 ${subText}`}>
                        Directorio de propietarios de vehículos registrados.
                    </p>
                </div>
                {/* Contador */}
                {!loading && (
                    <span className={`text-sm font-semibold px-3 py-1.5 rounded-xl border ${border} ${isDark ? 'bg-slate-800 text-slate-300' : 'bg-white text-slate-600'}`}>
                        {clientes.length} cliente{clientes.length !== 1 ? 's' : ''}
                    </span>
                )}
            </div>

            {/* Search */}
            <div className={`flex items-center gap-3 mb-6 p-2 rounded-2xl border ${border} ${isDark ? 'bg-slate-800/50' : 'bg-white'} shadow-sm shrink-0`}>
                <Search size={18} className={`ml-2 shrink-0 ${subText}`} />
                <input
                    type="text"
                    className={inputCls}
                    placeholder="Buscar por nombre, usuario o correo..."
                    value={query}
                    onChange={handleSearch}
                />
                <button
                    onClick={() => fetchClientes(query)}
                    className={`p-2 rounded-lg transition-colors ${isDark ? 'hover:bg-slate-700 text-slate-400' : 'hover:bg-slate-100 text-slate-500'}`}
                    title="Actualizar"
                >
                    <RefreshCw size={16} />
                </button>
            </div>

            {/* Content */}
            {loading ? (
                <div className="flex-1 flex items-center justify-center">
                    <Loader2 className="animate-spin text-blue-500" size={36} />
                </div>
            ) : clientes.length === 0 ? (
                <div className={`flex-1 flex flex-col items-center justify-center py-20 border-2 border-dashed ${border} rounded-2xl`}>
                    <Users className={`mb-4 opacity-30 ${isDark ? 'text-slate-500' : 'text-slate-300'}`} size={64} />
                    <h3 className={`text-xl font-bold ${textPrimary}`}>Sin clientes encontrados</h3>
                    <p className={`mt-2 ${subText}`}>
                        {query ? `No hay resultados para "${query}".` : 'Aún no hay clientes registrados en el sistema.'}
                    </p>
                    {query && (
                        <button
                            onClick={() => { setQuery(''); fetchClientes(''); }}
                            className="mt-4 text-sm text-blue-500 hover:underline"
                        >
                            Limpiar búsqueda
                        </button>
                    )}
                </div>
            ) : (
                <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-5">
                    {clientes.map(c => (
                        <div
                            key={c.id}
                            className={`${cardBg} border ${border} rounded-2xl overflow-hidden flex flex-col transition-all hover:shadow-lg hover:-translate-y-0.5 duration-200`}
                        >
                            {/* Barra de color superior */}
                            <div className={`h-1.5 ${getAvatarColor(c.id)}`} />

                            {/* Card Body */}
                            <div className="p-5 flex flex-col gap-4 flex-1">

                                {/* Avatar + nombre */}
                                <div className="flex items-center gap-4">
                                    <div className={`w-12 h-12 rounded-2xl flex items-center justify-center text-white font-bold text-lg shrink-0 ${getAvatarColor(c.id)}`}>
                                        {getInitials(c)}
                                    </div>
                                    <div className="min-w-0">
                                        <p className={`font-bold text-base leading-tight truncate ${textPrimary}`}>
                                            {c.full_name || c.username}
                                        </p>
                                        <p className={`text-xs truncate ${subText}`}>
                                            ID #{c.id}
                                        </p>
                                    </div>
                                </div>

                                {/* Detalles */}
                                <div className="flex flex-col gap-2">

                                    {/* Username */}
                                    <div className={`flex items-center gap-2 px-3 py-2 rounded-lg border ${border} ${isDark ? 'bg-slate-700/30' : 'bg-slate-50'}`}>
                                        <AtSign size={14} className="text-blue-400 shrink-0" />
                                        <div className="min-w-0">
                                            <p className={`text-xs ${subText}`}>Usuario</p>
                                            <p className={`text-sm font-semibold truncate ${textPrimary}`}>
                                                {c.username}
                                            </p>
                                        </div>
                                    </div>

                                    {/* Email */}
                                    <div className={`flex items-center gap-2 px-3 py-2 rounded-lg border ${border} ${isDark ? 'bg-slate-700/30' : 'bg-slate-50'}`}>
                                        <Mail size={14} className="text-emerald-400 shrink-0" />
                                        <div className="min-w-0">
                                            <p className={`text-xs ${subText}`}>Correo electrónico</p>
                                            <p className={`text-sm font-semibold truncate ${textPrimary}`}>
                                                {c.email || <span className={subText}>Sin correo</span>}
                                            </p>
                                        </div>
                                    </div>

                                    {/* Nombre completo si tiene first/last name diferente */}
                                    {(c.first_name || c.last_name) && (
                                        <div className={`flex items-center gap-2 px-3 py-2 rounded-lg border ${border} ${isDark ? 'bg-slate-700/30' : 'bg-slate-50'}`}>
                                            <User size={14} className="text-violet-400 shrink-0" />
                                            <div className="min-w-0">
                                                <p className={`text-xs ${subText}`}>Nombre completo</p>
                                                <p className={`text-sm font-semibold truncate ${textPrimary}`}>
                                                    {[c.first_name, c.last_name].filter(Boolean).join(' ')}
                                                </p>
                                            </div>
                                        </div>
                                    )}
                                </div>
                            </div>

                            {/* Footer */}
                            <div className={`px-5 py-3 border-t ${border} ${isDark ? 'bg-slate-800/50' : 'bg-slate-50'} flex items-center justify-end gap-2`}>
                                {c.email && (
                                    <a
                                        href={`mailto:${c.email}`}
                                        className="flex items-center gap-1.5 text-xs font-bold text-blue-400 hover:text-blue-300 transition-colors"
                                        title="Enviar correo"
                                    >
                                        <Mail size={14} /> Correo
                                    </a>
                                )}
                            </div>
                        </div>
                    ))}
                </div>
            )}
        </div>
    );
}
