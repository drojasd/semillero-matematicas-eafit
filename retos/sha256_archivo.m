function h = sha256_archivo(archivo)
% SHA256_ARCHIVO  Huella SHA-256 (hexadecimal, minúsculas) de los bytes de un archivo.
%
%   h = sha256_archivo('retos/privado/reto_2_verdad.json')
%
%   Es la misma huella que da `sha256sum` en Linux o `Get-FileHash` en Windows, y la misma que
%   calcula comun.sha256_archivo en Python.
    fid = fopen(archivo, 'r');
    if fid < 0
        error('sha256_archivo:noExiste', 'No se pudo abrir %s', archivo);
    end
    bytes = fread(fid, Inf, '*uint8');
    fclose(fid);
    md = java.security.MessageDigest.getInstance('SHA-256');
    md.update(bytes);
    d = typecast(md.digest(), 'uint8');
    h = lower(reshape(dec2hex(d, 2).', 1, []));
end
