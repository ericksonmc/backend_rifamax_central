class SecureHash
  def initialize(encryption_key)
    @key = Digest::SHA256.digest(encryption_key)
    @cipher = OpenSSL::Cipher.new('AES-256-CBC')
  end

  def encrypt_hash(hash)
    data = hash.to_json
    
    @cipher.encrypt
    @cipher.key = @key
    iv = @cipher.random_iv
    
    encrypted = @cipher.update(data) + @cipher.final
    Base64.strict_encode64(iv + encrypted)
  end

  def decrypt_hash(encrypted_string)
    raw_data = Base64.strict_decode64(encrypted_string)
    
    @cipher.decrypt
    @cipher.key = @key
    iv = raw_data[0..15]
    @cipher.iv = iv
    
    decrypted = @cipher.update(raw_data[16..-1]) + @cipher.final
    JSON.parse(decrypted)
  end
end