<?php
/*
  +------------------------------------------------------------------------+
  | PhalconEye CMS                                                         |
  +------------------------------------------------------------------------+
  | Copyright (c) 2013-2014 PhalconEye Team (http://phalconeye.com/)       |
  +------------------------------------------------------------------------+
  | This source file is subject to the New BSD License that is bundled     |
  | with this package in the file LICENSE.txt.                             |
  |                                                                        |
  | If you did not receive a copy of the license and are unable to         |
  | obtain it through the world-wide-web, please send an email             |
  | to license@phalconeye.com so we can send you a copy immediately.       |
  +------------------------------------------------------------------------+
  | Author: Ivan Vorontsov <ivan.vorontsov@phalconeye.com>                 |
  +------------------------------------------------------------------------+
*/

namespace User\Model;

use Core\Model\Access;
use Engine\Db\AbstractModel;

/**
 * Role.
 *
 * @category  PhalconEye
 * @package   User\Model
 * @author    Ivan Vorontsov <ivan.vorontsov@phalconeye.com>
 * @copyright 2013-2014 PhalconEye Team
 * @license   New BSD License
 * @link      http://phalconeye.com/
 *
 * @Source("roles")
 * @HasMany("id", '\User\Model\User', "role_id", {
 *  "alias": "User"
 * })
 * @HasMany("id", '\Core\Model\Access', "role_id", {
 *  "alias": "Access"
 * })
 */
class Role extends AbstractModel
{
    /**
     * @Primary
     * @Identity
     * @Column(type="integer", nullable=false, column="id", size="11")
     */
    public $id;

    /**
     * @Column(type="string", nullable=false, column="name", size="150")
     */
    public $name;

    /**
     * @Column(type="string", nullable=false, column="description", size="255")
     */
    public $description;

    /**
     * @Column(type="boolean", nullable=false, column="is_default")
     */
    public $is_default = false;

    /**
     * @Column(type="string", nullable=false, column="type", size="10")
     */
    public $type = 'user';

    /**
     * @Column(type="boolean", nullable=false, column="undeletable")
     */
    public $undeletable = false;

    /**
     * Return the related "User" entity.
     *
     * @param array $arguments Arguments data.
     *
     * @return User[]
     */
    public function getUser($arguments = [])
    {
        return $this->getRelated('User', $arguments);
    }

    /**
     * Return the related "Access" entity.
     *
     * @param array $arguments Arguments data.
     *
     * @return Access[]
     */
    public function getAccess($arguments = [])
    {
        return $this->getRelated('Access', $arguments);
    }

    /**
     * Some checks before validation.
     *
     * @return void
     */
    protected function beforeValidation()
    {
        if (empty($this->is_default)) {
            $this->is_default = 0;
        }
    }

    /**
     * Some logic before delete.
     *
     * @return void
     * @todo Refactor this.
     */
    protected function beforeDelete()
    {
        // cleanup acl
        $this->_modelsManager->executeQuery(
            "DELETE FROM Core\\Model\\Access WHERE role_id = " . $this->id . ""
        );
    }

    /**
     * Get guest role by type.
     *
     * @param string $type Role type.
     *
     * @return Role
     */
    public static function getRoleByType($type)
    {
        $role = Role::findFirst(
            [
                "type = '{$type}'",
                'cache' => [
                    'key' => 'role_type_' . $type . '.cache'
                ]
            ]
        );
        if (!$role) {
            $role = new Role();
            $role->name = ucfirst($type);
            $role->description = ucfirst($type) . ' role.';
            $role->type = $type;
            $role->undeletable = 1;
            $role->save();
        }

        return $role;
    }

    /**
     * Get default guest role.
     *
     * @return Role
     */
    public static function getDefaultRole()
    {
        $role = Role::findFirst(
            [
                "is_default = 1",
                'cache' => [
                    'key' => 'role_default.cache'
                ]
            ]
        );
        if (!$role) {
            $role = new Role();
            $role->name = "User";
            $role->description = 'Default user role.';
            $role->type = 'user';
            $role->undeletable = 1;
            $role->save();
        }

        return $role;
    }
}